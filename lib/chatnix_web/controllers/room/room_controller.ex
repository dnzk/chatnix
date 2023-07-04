defmodule ChatnixWeb.RoomController do
  use ChatnixWeb, :controller
  alias Chatnix.Conversation
  alias Chatnix.Auth
  alias Chatnix.Schemas.User

  plug ChatnixWeb.Authenticate

  def get_users(%{assigns: %{current_user: %User{}}} = conn, _) do
    render(conn, :get_users, users: Auth.get_users())
  end

  def get_users(conn, _) do
    conn
    |> put_status(:unauthorized)
    |> render(:get_users, error: %{message: "Unauthorized"})
  end

  def init_conversation(%{assigns: %{current_user: current_user}} = conn, %{
        "id" => id
      }) do
    room =
      Conversation.init_room(%{
        first: current_user,
        second: %{id: id}
      })

    case room do
      {:ok, r} ->
        render(conn, :init_conversation, room: r)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:init_conversation, error: %{message: "Error"})
    end
  end

  def init_conversation(conn, _) do
    conn
    |> put_status(:unauthorized)
    |> render(:init_conversation, error: %{message: "Unauthorized"})
  end

  def create_new_room(%{assigns: %{current_user: %{id: admin_id}}} = conn, %{
        "name" => room_name,
        "participants" => participants,
        "is_private" => is_private
      }) do
    case Conversation.create_room(
           %{
             name: room_name,
             admin: %{id: admin_id},
             participants: atomize_participants(participants)
           },
           is_private: is_private
         ) do
      {:ok, room} ->
        render(conn, :create_new_room, room: room)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:create_new_room, error: %{message: "Error"})
    end
  end

  def create_new_room(%{assigns: %{current_user: %{id: _}}} = conn, _) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(:create_new_room, error: %{message: "Error"})
  end

  def create_new_room(conn, _) do
    conn
    |> put_status(:unauthorized)
    |> render(:create_new_room, error: %{message: "Unauthorized"})
  end

  defp atomize_participants([%{"id" => id} | participants]) do
    atomize_participants(participants, [%{id: id}])
  end

  defp atomize_participants([%{"id" => id} | participants], result) do
    atomize_participants(participants, result ++ [%{id: id}])
  end

  defp atomize_participants([], result), do: result
end
