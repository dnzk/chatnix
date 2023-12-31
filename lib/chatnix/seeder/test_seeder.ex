defmodule Chatnix.Seeder.TestSeeder do
  @moduledoc """
  Test seeder
  """
  alias Chatnix.{Auth, Conversation}

  @spec seed :: :ok
  def seed() do
    {:ok, user_1} =
      Auth.create_user(%{
        username: "user_1",
        email: "user_1@example.com",
        password: "asdfasdfasdf"
      })

    {:ok, user_2} =
      Auth.create_user(%{
        username: "user_2",
        email: "user_2@example.com",
        password: "asdfasdfasdf"
      })

    {:ok, user_3} =
      Auth.create_user(%{
        username: "user_3",
        email: "user_3@example.com",
        password: "asdfasdfasdf"
      })

    {:ok, room} =
      Conversation.create_room(%{
        name: "Room 1",
        admin: user_1,
        participants: [user_2, user_3]
      })

    {:ok, room_1} =
      Conversation.create_room(
        %{
          name: "",
          admin: nil,
          participants: [user_3, user_1]
        },
        is_dm_room: true
      )

    {:ok, _room_2} =
      Conversation.create_room(%{
        name: "Room 2&3",
        admin: user_2,
        participants: [user_3]
      })

    Conversation.create_message(%{room_id: room.id, sender_id: user_1.id, message: "Hello"})

    Conversation.create_message(%{room_id: room_1.id, sender_id: user_1.id, message: "Hi there"})
    Conversation.create_message(%{room_id: room_1.id, sender_id: user_3.id, message: "Hi there"})

    :ok
  end
end
