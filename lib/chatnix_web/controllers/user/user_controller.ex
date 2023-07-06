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

  def sign_in(conn, %{"email" => email, "password" => password}) do
    with {:ok, user} <- Auth.authenticate_user(%{email: email, password: password}),
         {:ok, token, _claims} <-
           Chatnix.Guardian.encode_and_sign(user, %{username: user.username, email: user.email}) do
      render(conn, :sign_in, access_token: token)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(:sign_in, error: %{message: "Unauthorized"})
    end
  end
end
