defmodule Chatnix.Conversation do
  @moduledoc """
  Conversation context
  """
  alias Chatnix.Schemas.Room
  alias Chatnix.Repo

  @doc """
  Creates chat room.

  ## Parameters

    - name: The room's name
  """
  @spec create_room(String.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_room(name) do
    %{name: name}
    |> Room.insert_changeset()
    |> Repo.insert()
  end
end
