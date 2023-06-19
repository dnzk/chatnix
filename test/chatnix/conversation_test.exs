defmodule Chatnix.ConversationTest do
  @moduledoc """
  Conversation context test
  """
  use Chatnix.DataCase, async: true
  alias Chatnix.Conversation
  alias Chatnix.Repo
  alias Chatnix.Schemas.{Room, Message, RoomAccess, UsersRooms}
  alias Chatnix.TestHelpers.EctoChangeset

  describe "&create_room/1" do
    test "returns error when room name is taken" do
      assert {:error, changeset} =
               Conversation.create_room(%{
                 name: "Room 1",
                 admin: %{id: 1},
                 participants: [
                   %{id: 2},
                   %{id: 3}
                 ],
                 is_private: false
               })

      assert EctoChangeset.fetch_error_constraint(changeset, :name, :constraint) === :unique
    end

    test "returns error when room name is shorter than 3" do
      assert {:error, changeset} =
               Conversation.create_room(%{
                 name: "22",
                 admin: %{id: 1},
                 participants: [%{id: 2}],
                 is_private: false
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
                 ],
                 is_private: false
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
                 ],
                 is_private: false
               })
    end

    test "room creator becomes the admin" do
      assert {:ok, room} =
               Conversation.create_room(%{
                 name: "Room 2",
                 admin: %{id: 1},
                 participants: [
                   %{id: 2},
                   %{id: 3}
                 ],
                 is_private: false
               })

      users_rooms = Repo.get_by(UsersRooms, user_id: 1, room_id: room.id)
      access_rights = Repo.get_by(RoomAccess, users_rooms_id: users_rooms.id)
      assert access_rights.is_admin
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
end
