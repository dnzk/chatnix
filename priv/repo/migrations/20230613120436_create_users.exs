defmodule Chatnix.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table("users") do
      add :username, :string
      add :email, :string
      add :password_hash, :string

      timestamps()
    end

    create unique_index("users", [:username], name: "users_username_index")
    create unique_index("users", [:email], name: "users_email_index")
  end
end
