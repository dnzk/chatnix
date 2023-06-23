defmodule Chatnix.Schemas.RoomAccess do
  @moduledoc """
  Room access schema
  """
  alias Chatnix.Schemas.UsersRooms
  alias __MODULE__
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "room_accesses" do
    field :is_admin, :boolean

    belongs_to :users_rooms, Chatnix.Schemas.UsersRooms

    timestamps()
  end

  def changeset(room_access \\ %RoomAccess{}, params) do
    room_access
    |> cast(params, [:is_admin])
    |> validate_required([:is_admin])
  end

  def get_by_room(query \\ RoomAccess, room_id) do
    from ra in query,
      join: ur in UsersRooms,
      on: ra.users_rooms_id == ur.id,
      where: ur.room_id == ^room_id
  end
end
