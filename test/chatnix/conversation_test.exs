defmodule Chatnix.ConversationTest do
  @moduledoc """
  Conversation context test
  """
  use Chatnix.DataCase, async: true
  alias Chatnix.Conversation
  alias Chatnix.Repo
  alias Chatnix.Schemas.{Room, Message, RoomAccess, UsersRooms, User}
  alias Chatnix.TestHelpers.EctoChangeset
  alias Chatnix.Auth
  doctest Chatnix.Conversation

  describe "&create_room/1 without options" do
    test "returns error when room name is taken" do
      assert {:error, changeset} =
               Conversation.create_room(%{
                 name: "Room 1",
                 admin: %{id: 1},
                 participants: [
                   %{id: 2},
                   %{id: 3}
                 ]
               })

      assert EctoChangeset.fetch_error_constraint(changeset, :name, :constraint) === :unique
    end

    test "returns error when room name is shorter than 3" do
      assert {:error, changeset} =
               Conversation.create_room(%{
                 name: "22",
                 admin: %{id: 1},
                 participants: [%{id: 2}]
               })

      assert EctoChangeset.fetch_error_constraint(changeset, :name, :validation) === :length
      assert EctoChangeset.fetch_error_constraint(changeset, :name, :kind) === :min
    end

    test "does not create room when user IDs are invalid" do
      assert {:error, _error} =
               Conversation.create_room(%{
                 name: "Room 2",
                 admin: %{id: 101},
                 participants: [
                   %{id: 100},
                   %{id: 200}
                 ]
               })

      new_room = Repo.get_by(Room, name: "Room 2")
      assert is_nil(new_room)
    end

    test "creates room with valid params" do
      assert {:ok, _room} =
               Conversation.create_room(%{
                 name: "Room 2",
                 admin: %{id: 1},
                 participants: [
                   %{id: 2},
                   %{id: 3}
                 ]
               })
    end

    test "is_private and is_dm_room default to false" do
      assert {:ok, room} =
               Conversation.create_room(%{
                 name: "Room 3",
                 admin: %{id: 1},
                 participants: [%{id: 2}]
               })

      assert room.is_private === false
      assert room.is_dm_room === false
    end

    test "room creator becomes the admin" do
      assert {:ok, room} =
               Conversation.create_room(%{
                 name: "Room 2",
                 admin: %{id: 1},
                 participants: [
                   %{id: 2},
                   %{id: 3}
                 ]
               })

      users_rooms = Repo.get_by(UsersRooms, user_id: 1, room_id: room.id)
      access_rights = Repo.get_by(RoomAccess, users_rooms_id: users_rooms.id)
      assert access_rights.is_admin
    end

    test "creates room with empty participants" do
      assert {:ok, _room} =
               Conversation.create_room(%{
                 name: "Empty room",
                 admin: %{id: 1},
                 participants: []
               })
    end
  end

  describe "&delete_room/1" do
    test "returns error when room id does not exist" do
      assert {:error, _} = Conversation.delete_room(300)
    end

    test "deletes room when room id is valid" do
      assert {:ok, _} = Conversation.delete_room(1)

      assert is_nil(Repo.get(Room, 1))
    end
  end

  describe "&create_room/1 when is_dm_room is true" do
    test "returns error when participants are not exactly two different users" do
      assert {:error, _r} =
               Conversation.create_room(
                 %{
                   name: "",
                   admin: nil,
                   participants: [%{id: 1}]
                 },
                 is_dm_room: true
               )

      assert {:error, _r} =
               Conversation.create_room(
                 %{
                   name: "",
                   admin: nil,
                   participants: [%{id: 1}, %{id: 2}, %{id: 3}]
                 },
                 is_dm_room: true
               )
    end

    test "creates room without admin" do
      assert {:ok, room} =
               Conversation.create_room(
                 %{
                   name: "",
                   admin: nil,
                   participants: [%{id: 1}, %{id: 2}]
                 },
                 is_dm_room: true
               )

      room_access =
        RoomAccess
        |> RoomAccess.get_by_room(room.id)
        |> Repo.one()

      assert is_nil(room_access)
    end

    test "sets is_dm_room and is_private to true" do
      assert {:ok, room} =
               Conversation.create_room(
                 %{
                   name: "",
                   admin: nil,
                   participants: [%{id: 1}, %{id: 2}]
                 },
                 is_dm_room: true
               )

      assert room.is_dm_room
      assert room.is_private
    end

    test "room with the same set of participants can only be created once" do
      assert {:error, _r} =
               Conversation.create_room(
                 %{
                   name: "",
                   admin: nil,
                   participants: [%{id: 3}, %{id: 1}]
                 },
                 is_dm_room: true
               )
    end
  end

  describe "&create_message/1" do
    test "returns error when message is less than one character" do
      assert {:error, _error} =
               Conversation.create_message(%{sender_id: 1, room_id: 1, message: ""})
    end

    test "returns error when room_id does not exist" do
      assert {:error, _error} =
               Conversation.create_message(%{sender_id: 1, room_id: 1000, message: "Test"})
    end

    test "returns error when user_id does not exist" do
      assert {:error, _error} =
               Conversation.create_message(%{sender_id: 1000, room_id: 1, message: "Test"})
    end

    test "creates message with valid params" do
      assert {:ok, _message} =
               Conversation.create_message(%{sender_id: 1, room_id: 1, message: "Test"})
    end
  end

  describe "&delete_message/1" do
    test "returns error when user_id does not exist" do
      assert {:error, _message} = Conversation.delete_message(%{user_id: 100, message_id: 1})
    end

    test "returns error when message_id does not exist" do
      assert {:error, _message} = Conversation.delete_message(%{user_id: 1, message_id: 100})
    end

    test "returns error when message does not belong to the user" do
      assert {:error, _message} = Conversation.delete_message(%{user_id: 2, message_id: 1})
    end

    test "deletes the message with valid params" do
      assert {:ok, _message} = Conversation.delete_message(%{user_id: 1, message_id: 1})
    end
  end

  describe "&update_message/1" do
    test "returns error when user_id does not exist" do
      assert {:error, _message} =
               Conversation.update_message(%{
                 user_id: 10,
                 message_id: 1,
                 message: "Hello"
               })
    end

    test "returns error when message_id does not exist" do
      assert {:error, _message} =
               Conversation.update_message(%{
                 user_id: 1,
                 message_id: 10,
                 message: "Hello"
               })
    end

    test "returns error when message is empty" do
      assert {:error, _message} =
               Conversation.update_message(%{
                 user_id: 1,
                 message_id: 1,
                 message: ""
               })
    end

    test "returns error when the user does not own the message" do
      assert {:error, _message} =
               Conversation.update_message(%{
                 user_id: 2,
                 message_id: 1,
                 message: "Hello"
               })
    end

    test "updates message with valid params" do
      old_message = Repo.get(Message, 1)
      new_message = "This is the new message"

      assert {:ok, message} =
               Conversation.update_message(%{
                 user_id: 1,
                 message_id: 1,
                 message: new_message
               })

      assert !is_nil(message.content)
      assert message.content !== old_message
    end
  end

  describe "&add_users_to_room/1" do
    test "returns error when admin does not exist" do
      assert {:error, _error} =
               Conversation.add_users_to_room(%{
                 admin: %{id: 100},
                 users: [%{id: 1}],
                 room: %{id: 1}
               })
    end

    test "returns error when room does not exist" do
      assert {:error, _error} =
               Conversation.add_users_to_room(%{
                 admin: %{id: 1},
                 users: [%{id: 1}],
                 room: %{id: 100}
               })
    end

    test "returns error when room does not belong to admin" do
      assert {:error, _error} =
               Conversation.add_users_to_room(%{
                 admin: %{id: 2},
                 users: [%{id: 1}],
                 room: %{id: 1}
               })
    end

    test "does not duplicate user connections" do
      q = from(ur in UsersRooms, where: ur.user_id in [1, 2, 3])
      user_room_connections = Repo.all(q)

      assert length(user_room_connections) === 7

      assert {:ok, _updated} =
               Conversation.add_users_to_room(%{
                 admin: %{id: 1},
                 users: [%{id: 2}, %{id: 3}],
                 room: %{id: 1}
               })

      user_room_connections = Repo.all(q)

      assert length(user_room_connections) === 7
    end

    test "adds users to room with valid params" do
      {:ok, room} =
        Conversation.create_room(%{
          name: "test room",
          participants: [],
          admin: %{id: 1}
        })

      q = from(ur in UsersRooms, where: ur.room_id == ^room.id)
      assert length(Repo.all(q)) == 1

      {:ok, user_a} =
        Auth.create_user(%{
          email: "user_a@example.com",
          username: "user_a",
          password: "asdfasdfasdfasdf"
        })

      {:ok, user_b} =
        Auth.create_user(%{
          email: "user_b@example.com",
          username: "user_b",
          password: "asdfasdfasdfasdf"
        })

      Conversation.add_users_to_room(%{
        admin: %{id: 1},
        room: %{id: room.id},
        users: [%{id: user_a.id}, %{id: user_b.id}]
      })

      assert length(Repo.all(q)) == 3
    end
  end

  describe "&remove_users_from_room/1" do
    test "returns error when admin does not exist" do
      assert {:error, _error} =
               Conversation.remove_users_from_room(%{admin: %{id: 100}, room: %{id: 1}, users: []})
    end

    test "return error when room does not exist" do
      assert {:error, _error} =
               Conversation.remove_users_from_room(%{admin: %{id: 1}, room: %{id: 100}, users: []})
    end

    test "return error when room does not belong to admin" do
      assert {:error, _error} =
               Conversation.remove_users_from_room(%{admin: %{id: 2}, room: %{id: 1}, users: []})
    end

    test "removes users from room" do
      assert {:ok, _room} =
               Conversation.remove_users_from_room(%{
                 admin: %{id: 1},
                 room: %{id: 1},
                 users: [%{id: 2}]
               })

      assert is_nil(Repo.get_by(UsersRooms, user_id: 2, room_id: 1))
    end
  end

  describe "&send_message_to_room/1" do
    test "returns error when user does not exist" do
      assert {:error, _e} =
               Conversation.send_message_to_room(%{
                 message: "Hey room",
                 room: %{id: 1},
                 sender: %{id: 100}
               })
    end

    test "returns error when room does not exist" do
      assert {:error, _e} =
               Conversation.send_message_to_room(%{
                 message: "Hey room",
                 room: %{id: 100},
                 sender: %{id: 1}
               })
    end

    test "returns error when message is empty" do
      assert {:error, _e} =
               Conversation.send_message_to_room(%{
                 message: "",
                 room: %{id: 1},
                 sender: %{id: 1}
               })
    end

    test "return error when user does not belong in the room" do
      {:ok, user_a} =
        Auth.create_user(%{
          email: "user_a@example.com",
          username: "user_a",
          password: "asdfasdfasdf"
        })

      assert {:error, _e} =
               Conversation.send_message_to_room(%{
                 message: "Hey room",
                 room: %{id: 1},
                 sender: %{id: user_a.id}
               })
    end

    test "sends message to room with valid params" do
      assert {:ok, r} =
               Conversation.send_message_to_room(%{
                 message: "Hey room",
                 room: %{id: 1},
                 sender: %{id: 2}
               })

      ur = Repo.get_by(UsersRooms, room_id: 1, user_id: 2)
      m = Repo.get_by(Message, users_rooms_id: ur.id, id: r.id)
      assert !is_nil(m)
    end
  end

  describe "&read_messages_in_room/1" do
    test "returns error when room does not exist" do
      assert {:error, _error} =
               Conversation.read_messages_in_room(%{room: %{id: 100}, user: %{id: 1}})
    end

    test "returns error when user does not belong to room and room is private" do
      {:ok, user_a} =
        Auth.create_user(%{
          email: "user_a@example.com",
          username: "user_a",
          password: "asdfasdfasdfasdf"
        })

      {:ok, room} =
        Conversation.create_room(
          %{
            name: "Private",
            participants: [%{id: 2}, %{id: 3}],
            admin: %{id: 1}
          },
          is_private: true
        )

      assert {:error, _error} =
               Conversation.read_messages_in_room(%{
                 user: user_a,
                 room: room
               })
    end

    test "returns messages for user who does not belong in the non private room" do
      {:ok, user_a} =
        Auth.create_user(%{
          email: "user_a@example.com",
          username: "user_a",
          password: "asdfasdfasdfasdf"
        })

      Conversation.send_message_to_room(%{sender: %{id: 1}, room: %{id: 1}, message: "Hi"})
      Conversation.send_message_to_room(%{sender: %{id: 3}, room: %{id: 1}, message: "Hello"})

      assert {:ok, messages} =
               Conversation.read_messages_in_room(%{
                 room: %{id: 1},
                 user: user_a
               })

      assert length(messages) == 3
    end

    test "returns messages for user who belongs in the private room" do
      {:ok, room} =
        Conversation.create_room(%{
          name: "Private",
          participants: [%{id: 2}, %{id: 3}],
          admin: %{id: 1},
          is_private: true
        })

      Conversation.send_message_to_room(%{sender: %{id: 2}, room: room, message: "Hi"})

      Conversation.send_message_to_room(%{sender: %{id: 3}, room: room, message: "Hello"})

      assert {:ok, messages} = Conversation.read_messages_in_room(%{room: room, user: %{id: 1}})

      assert length(messages) == 2
    end

    test "returns messages for user who belongs in the non private room" do
      Conversation.send_message_to_room(%{sender: %{id: 1}, room: %{id: 1}, message: "Hi"})
      Conversation.send_message_to_room(%{sender: %{id: 3}, room: %{id: 1}, message: "Hello"})

      assert {:ok, messages} =
               Conversation.read_messages_in_room(%{room: %{id: 1}, user: %{id: 1}})

      assert length(messages) === 3
    end
  end

  describe "&get_all_rooms/0" do
    test "returns list of all rooms" do
      Conversation.create_room(
        %{
          name: "Room 2",
          participants: [%{id: 2}],
          admin: %{id: 1}
        },
        is_private: true
      )

      Conversation.create_room(
        %{
          name: "Room 3",
          participants: [%{id: 3}],
          admin: %{id: 2}
        },
        is_private: true
      )

      assert {:ok, rooms} = Conversation.get_all_rooms()
      assert length(rooms) === 5
    end
  end

  describe "&get_rooms_for_user/1" do
    test "returns list of all rooms the user id is part of" do
      assert {:ok, rooms} = Conversation.get_rooms_for_user(1)

      for room <- rooms,
          do: assert(!is_nil(Repo.get_by(UsersRooms, user_id: 1, room_id: room.id)))
    end
  end

  describe "&init_room/1" do
    test "success: initializing existing room returns the room" do
      assert {:ok, %Room{}} =
               Conversation.init_room(%{
                 first: %{id: 1},
                 second: %{id: 3}
               })
    end

    test "success: initializing non existing room creates and returns the room" do
      {:ok, user_4} =
        Auth.create_user(%{
          email: "user_yu@example.com",
          username: "user_yu",
          password: "asdfasdfasdf"
        })

      assert {:ok, %Room{}} =
               Conversation.init_room(%{
                 first: user_4,
                 second: %{id: 1}
               })
    end

    test "success: adds messages to the room" do
      {:ok, %Room{messages: messages}} =
        Conversation.init_room(%{first: %{id: 1}, second: %{id: 3}})

      assert length(messages) !== 0
    end

    test "success: initializing a DM room returns the second user's name as room name" do
      user_2 = Repo.get(User, 2)
      {:ok, %Room{name: name}} = Conversation.init_room(%{first: %{id: 1}, second: %{id: 2}})

      assert name === user_2.username
    end

    test "error: initializing with the same users id" do
      {:error, _} = Conversation.init_room(%{first: %{id: 1}, second: %{id: 1}})
    end
  end
end
