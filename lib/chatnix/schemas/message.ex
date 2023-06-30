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

  @derive {Jason.Encoder, only: [:id, :content, :sent_by, :sent_datetime]}

  schema "messages" do
    field :content, :string
    field :sent_by, :id, virtual: true
    field :sent_datetime, :utc_datetime, virtual: true

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

  def get_by_room(query \\ Message, room_id, limit \\ 20) do
    from m in query,
      join: ur in UsersRooms,
      on: m.users_rooms_id == ur.id,
      where: ur.room_id == ^room_id,
      limit: ^limit,
      select: %{
        content: m.content,
        sent_datetime: m.inserted_at,
        sent_by: ur.user_id,
        id: m.id
      }
  end
end
