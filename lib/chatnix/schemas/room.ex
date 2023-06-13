defmodule Chatnix.Schemas.Room do
  @moduledoc """
  Room schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  @type t :: %Room{}

  schema "rooms" do
    field :name, :string

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
