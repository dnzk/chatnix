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

  @derive {Jason.Encoder, only: [:id, :name, :messages]}

  @type t :: %Room{}
  @type id :: String.t() | integer()

  schema "rooms" do
    field :name, :string
    field :is_private, :boolean
    field :is_dm_room, :boolean

    many_to_many :users, User, join_through: "users_rooms"
    field :messages, {:array, :map}, virtual: true

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

  def query_dm_room([user_1_id | [user_2_id | _]]) do
    from r1 in subquery(get_room_by_user(user_1_id)),
      join: r2 in subquery(get_room_by_user(user_2_id)),
      on: r1.id == r2.id,
      where: r1.is_dm_room
  end

  def get_room_by_user(user_id) do
    from r in Room,
      join: ur in UsersRooms,
      on: ur.room_id == r.id,
      where: ur.user_id == ^user_id
  end

  def get_group_room_by_user(user_id) do
    from r in Room,
      join: ur in UsersRooms,
      on: ur.room_id == r.id,
      where: ur.user_id == ^user_id,
      where: not r.is_dm_room
  end
end
