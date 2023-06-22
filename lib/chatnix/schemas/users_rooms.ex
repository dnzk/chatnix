defmodule Chatnix.Schemas.UsersRooms do
  @moduledoc """
  UsersRooms schema
  """
  alias __MODULE__
  use Ecto.Schema
  alias Chatnix.Schemas.{Room, User, Message}
  import Ecto.Query

  @type t :: %UsersRooms{}

  schema "users_rooms" do
    belongs_to :user, User
    belongs_to :room, Room
    has_many :messages, Message
  end

  def get_by_room_and_users(UsersRooms = query, room_id, users_id) do
    from q in query, where: q.room_id == ^room_id and q.user_id in ^users_id
  end
end
