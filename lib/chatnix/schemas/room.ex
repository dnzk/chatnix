defmodule Chatnix.Schemas.Room do
  @moduledoc """
  Room schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__
  alias Chatnix.Schemas.User

  @type t :: %Room{}

  schema "rooms" do
    field :name, :string

    many_to_many :users, User, join_through: "users_rooms"

    timestamps()
  end

  def insert_changeset(params) do
    %Room{}
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 3)
    |> unique_constraint(:name)
  end
end
