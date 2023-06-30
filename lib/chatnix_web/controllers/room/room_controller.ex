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
end
