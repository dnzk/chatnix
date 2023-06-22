defmodule Chatnix.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table("rooms") do
      add :name, :string
      add :is_private, :boolean
      add :is_dm_room, :boolean

      timestamps()
    end

    create unique_index("rooms", [:name], name: "rooms_name_index")
  end
end
