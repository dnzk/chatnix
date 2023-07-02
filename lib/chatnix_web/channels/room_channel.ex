defmodule ChatnixWeb.RoomChannel do
  @moduledoc """
  Room channel
  """
  use Phoenix.Channel
  alias Chatnix.Conversation
  alias Chatnix.Schemas.User
  alias Phoenix.Socket

  def join(
        "room:" <> room_id,
        _params,
        %Socket{
          assigns: %{
            current_user: %User{}
          }
        } = socket
      ) do
    {:ok, assign(socket, :room, %{id: room_id})}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "Unauthorized"}}
  end

  def handle_in(
        "new_message",
        %{"message" => message},
        %Socket{
          assigns: %{
            current_user: current_user,
            room: %{id: room_id}
          }
        } = socket
      ) do
    with {:ok, created_message} <-
           Conversation.create_message(%{
             message: message,
             sender_id: current_user.id,
             room_id: room_id
           }),
         :ok <-
           broadcast(socket, "new_message", %{
             created_message
             | sent_by: current_user,
               sent_datetime: DateTime.now!("Etc/UTC")
           }) do
      {:reply, :ok, socket}
    else
      _ -> {:reply, :error, socket}
    end
  end

  def handle_in(_, _, socket) do
    {:noreply, socket}
  end
end
