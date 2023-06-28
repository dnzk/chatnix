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

    {:ok, _room_1} =
      Conversation.create_room(
        %{
          name: "",
          admin: nil,
          participants: [user_3, user_1]
        },
        is_dm_room: true
      )

    Conversation.create_message(%{room_id: room.id, sender_id: user_1.id, message: "Hello"})

    :ok
  end
end
