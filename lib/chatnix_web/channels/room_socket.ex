defmodule ChatnixWeb.RoomSocket do
  use Phoenix.Socket
  alias Chatnix.Guardian

  channel "room:*", ChatnixWeb.RoomChannel

  @impl true
  def connect(%{"accessToken" => accessToken}, socket, _connect_info) do
    case Guardian.authenticate_token(accessToken) do
      {:ok, user} ->
        {:ok, assign(socket, :current_user, user)}

      _ ->
        {:error, :unauthorized}
    end
  end

  def connect(_, _socket, _connect_info) do
    {:error, :unauthorized}
  end

  @impl true
  def id(_socket), do: nil
end
