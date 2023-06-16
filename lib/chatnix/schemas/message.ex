defmodule Chatnix.Schemas.Message do
  @moduledoc """
  Message schema
  """
  alias __MODULE__
  use Ecto.Schema
  import Ecto.Changeset
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
end
