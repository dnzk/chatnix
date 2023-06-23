defmodule Chatnix.Schemas.Room do
  @moduledoc """
  Room schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Chatnix.Schemas.UsersRooms
  alias __MODULE__
  alias Chatnix.Schemas.User
  import Ecto.Query

  @type t :: %Room{}

  schema "rooms" do
    field :name, :string
    field :is_private, :boolean
    field :is_dm_room, :boolean

    many_to_many :users, User, join_through: "users_rooms"

    timestamps()
  end

  @required_params [:name, :is_private, :is_dm_room]

  def insert_changeset(params) do
    %Room{}
    |> cast(params, @required_params)
    |> validate_required(@required_params)
    |> validate_length(:name, min: 3)
    |> unique_constraint(:name)
  end

  def query_dm_room(user_ids) do
    from r in Room,
      join: ur in UsersRooms,
      on: ur.room_id == r.id,
      where: ur.user_id in ^user_ids,
      where: r.is_dm_room,
      select: count()
  end
end
