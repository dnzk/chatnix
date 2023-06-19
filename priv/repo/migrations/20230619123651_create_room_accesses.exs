defmodule Chatnix.Repo.Migrations.CreateRoomAccesses do
  use Ecto.Migration

  def change do
    create table("room_accesses") do
      add :is_admin, :boolean
      add :users_rooms_id, references(:users_rooms, on_delete: :delete_all)

      timestamps()
    end
  end
end
