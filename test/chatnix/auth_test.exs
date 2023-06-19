defmodule Chatnix.AuthTest do
  @moduledoc """
  Auth context test
  """
  use Chatnix.DataCase, async: true
  alias Chatnix.Auth
  alias Chatnix.TestHelpers.EctoChangeset

  describe "&create_user/1" do
    test "returns error when email is taken" do
      assert {:error, changeset} =
               Auth.create_user(%{
                 username: "user_0",
                 email: "user_1@example.com",
                 password: "asdfasdfasdasdf"
               })

      assert EctoChangeset.fetch_error_constraint(changeset, :email, :constraint) === :unique
    end

    test "returns error when username is too short" do
      assert {:error, changeset} =
               Auth.create_user(%{
                 username: "abc",
                 email: "user_abc@example.com",
                 password: "asdfasdfasdfasdf"
               })

      assert EctoChangeset.fetch_error_constraint(changeset, :username, :validation) === :length
      assert EctoChangeset.fetch_error_constraint(changeset, :username, :kind) === :min
    end

    test "returns error when email is formatted incorrectly" do
      assert {:error, changeset} =
               Auth.create_user(%{
                 username: "user_2",
                 email: "user_2_(at)_example.com",
                 password: "asdfasdfasdfasdf"
               })

      assert EctoChangeset.fetch_error_constraint(changeset, :email, :validation) === :format
    end

    test "returns error when username is taken" do
      assert {:error, changeset} =
               Auth.create_user(%{
                 username: "user_1",
                 email: "user_2@example.com",
                 password: "asdfasdfasdfasdf"
               })

      assert EctoChangeset.fetch_error_constraint(changeset, :username, :constraint) === :unique
    end

    test "creates user with valid params" do
      assert {:ok, _u} =
               Auth.create_user(%{
                 username: "valid_user",
                 email: "valid_email@example.com",
                 password: "asdfasdfasdfasdf"
               })
    end

    test "saves hashed password" do
      password = "asdfasdfasdfasdf"

      assert {:ok, user} =
               Auth.create_user(%{
                 username: "valid_user",
                 email: "valid_email@example.com",
                 password: password
               })

      assert !is_nil(user.password_hash)
      assert user.password_hash !== password
      assert {:ok, _u} = Pbkdf2.check_pass(user, password)
    end
  end
end
