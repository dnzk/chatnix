defmodule ChatnixWeb.RoomChannelTest do
  @moduledoc """
  Room channel test
  """
  use ChatnixWeb.ChannelCase
  alias Chatnix.Repo
  alias Chatnix.Schemas.{User, Message}

  describe "Sending message as authorized user" do
    setup do
      current_user = Repo.get(User, 1)

      {:ok, _, socket} =
        ChatnixWeb.RoomSocket
        |> socket("user_id", %{current_user: current_user})
        |> subscribe_and_join(ChatnixWeb.RoomChannel, "room:1")

      %{socket: socket}
    end

    test "new_message broadcasts new_message", %{socket: socket} do
      push(socket, "new_message", %{"message" => "Hello there"})
      assert_broadcast "new_message", %Message{content: "Hello there"}
    end
  end

  describe "Unauthorized user" do
    test "cannot join room" do
      assert {:error, %{reason: "Unauthorized"}} =
               ChatnixWeb.RoomSocket
               |> socket("user_id", %{})
               |> subscribe_and_join(ChatnixWeb.RoomChannel, "room:1")
    end
  end
end
