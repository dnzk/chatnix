defmodule ChatnixWeb.UserControllerTest do
  @moduledoc """
  User controller test
  """
  use ChatnixWeb.ConnCase, async: true

  describe "sign_up" do
    test "creates users and returns 200 for valid params", %{conn: conn} do
      assert %{status: 200} =
               post(conn, ~p"/api/sign_up", %{
                 "username" => "some_Us3r",
                 "email" => "some_user@example.com",
                 "password" => "asdfasdfasdf"
               })

      assert %{email: "some_user@example.com"} =
               Chatnix.Repo.get_by(Chatnix.Schemas.User, username: "some_Us3r")
    end

    test "return 422 for invalid params", %{conn: conn} do
      Chatnix.Auth.create_user(%{
        username: "user_123",
        email: "user_123@example.com",
        password: "asdfasdfasdf"
      })

      assert %{status: 422} =
               post(conn, ~p"/api/sign_up", %{
                 "username" => "user_123",
                 "email" => "user_123@example.com",
                 "password" => "asdfasdfasdf"
               })
    end
  end
end
