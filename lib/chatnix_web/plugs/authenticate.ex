defmodule ChatnixWeb.Authenticate do
  @moduledoc """
  Authenticate plug
  """

  @behaviour Plug

  import Plug.Conn
  alias Chatnix.Guardian

  def init(opts), do: opts

  def call(conn, _) do
    maybe_put_current_user(conn)
  end

  defp maybe_put_current_user(%Plug.Conn{} = conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, current_user} when not is_nil(current_user) <- Guardian.authenticate_token(token) do
      assign(conn, :current_user, current_user)
    else
      _ -> conn
    end
  end
end
