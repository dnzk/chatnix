defmodule Chatnix.Schemas.UsersRooms do
  @moduledoc """
  UsersRooms schema
  """
  use Ecto.Schema
  alias Chatnix.Schemas.{Room, User, Message}

  schema "users_rooms" do
    belongs_to :user, User
    belongs_to :room, Room
    has_many :messages, Message
  end
end
