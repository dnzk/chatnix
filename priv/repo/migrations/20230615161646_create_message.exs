defmodule Chatnix.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table("messages") do
      add :users_rooms_id, references(:users_rooms, on_delete: :delete_all)
      add :content, :string

      timestamps()
    end
  end
end
