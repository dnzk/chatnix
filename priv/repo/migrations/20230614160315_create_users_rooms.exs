defmodule Chatnix.Repo.Migrations.CreateUsersRooms do
  use Ecto.Migration

  def change do
    create table("users_rooms") do
      add :user_id, references(:users, on_delete: :delete_all)
      add :room_id, references(:rooms, on_delete: :delete_all)
    end

    create unique_index("users_rooms", [:user_id, :room_id])
  end
end
