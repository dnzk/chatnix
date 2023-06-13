defmodule Chatnix.Schemas.User do
  @moduledoc """
  User schema
  """
  alias __MODULE__
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %User{}

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string, redact: true
    field :password, :string, redact: true, virtual: true

    timestamps()
  end

  def insert_changeset(params \\ %{}) do
    %User{}
    |> cast(params, [:username, :email, :password])
    |> validate_required([:username, :email, :password])
    |> validate_length(:username, min: 4)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> validate_length(:password, min: 12, max: 200)
    |> put_pass_hash()
  end

  defp put_pass_hash(
         %Ecto.Changeset{
           valid?: true,
           changes: %{password: password}
         } = changeset
       ) do
    change(changeset, Pbkdf2.add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
