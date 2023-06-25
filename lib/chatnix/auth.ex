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

  @doc """
  Authenticates user.

  ## Parameters

    - email: The user's email
    - password: The user's password
  """
  @spec authenticate_user(%{
          required(:email) => String.t(),
          required(:password) => String.t()
        }) ::
          {:error, any()}
          | {:ok, User.t()}
  def authenticate_user(%{email: email, password: password}) do
    with user when not is_nil(user) <- get_user(%{email: email}),
         true <- Pbkdf2.verify_pass(password, user.password_hash) do
      {:ok, user}
    else
      _ ->
        Pbkdf2.no_user_verify()
        {:error, "Invalid credentials"}
    end
  end

  @doc """
  Gets a user.

  ## Parameters

    - email: User's email
    - id: User's id
  """
  @spec get_user(%{
          :email => String.t()
        }) :: User.t() | nil
  def get_user(%{email: email}) do
    Repo.get_by(User, email: email)
  end

  @spec get_user(%{
          :id => User.id()
        }) :: User.t() | nil
  def get_user(%{id: id}) do
    Repo.get(User, id)
  end
end
