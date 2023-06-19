defmodule Chatnix.Schemas.RoomAccess do
  @moduledoc """
  Room access schema
  """
  alias __MODULE__
  use Ecto.Schema
  import Ecto.Changeset

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
end
