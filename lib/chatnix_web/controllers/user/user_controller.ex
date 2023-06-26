defmodule ChatnixWeb.UserController do
  use ChatnixWeb, :controller
  alias Chatnix.Auth

  def sign_up(conn, %{"username" => username, "email" => email, "password" => password}) do
    case Auth.create_user(%{username: username, email: email, password: password}) do
      {:ok, user} ->
        render(
          conn,
          :sign_up,
          user: %{
            username: user.username,
            email: user.email
          }
        )

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:sign_up, error: %{message: "Something went wrong"})
    end
  end
end
