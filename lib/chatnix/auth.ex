defmodule Chatnix.Auth do
  @moduledoc """
  Auth context
  """
  alias Chatnix.Schemas.User
  alias Chatnix.Repo

  @doc """
  Creates user with the supplied params.

  ## Parameters

    - email: The user's email string.
    - password: User's plain text password.
    - username: The user's username
  """
  @spec create_user(%{
          :email => String.t(),
          :password => String.t(),
          :username => String.t()
        }) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_user(%{username: _, email: _, password: _} = params) do
    params
    |> User.insert_changeset()
    |> Repo.insert()
  end
end
