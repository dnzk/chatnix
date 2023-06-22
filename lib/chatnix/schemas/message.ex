defmodule Chatnix.Schemas.Message do
  @moduledoc """
  Message schema
  """
  alias __MODULE__
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Chatnix.Schemas.UsersRooms

  @type t :: %Message{}

  schema "messages" do
    field :content, :string

    belongs_to :users_rooms, UsersRooms

    timestamps()
  end

  def insert_changeset(params) do
    %Message{}
    |> cast(params, [:content])
    |> validate_required([:content])
    |> validate_length(:content, min: 1)
  end

  def changeset(%Message{} = message, params) do
    message
    |> cast(params, [:content])
    |> validate_required([:content])
    |> validate_length(:content, min: 1)
  end

  def get_by_room(query \\ Message, room_id) do
    from m in query,
      join: ur in UsersRooms,
      on: m.users_rooms_id == ur.id,
      where: ur.room_id == ^room_id
  end
end
