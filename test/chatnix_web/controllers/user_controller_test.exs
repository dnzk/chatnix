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

  describe "sign_in" do
    test "returns 200 and access_token when valid", %{conn: conn} do
      assert %{status: 200, resp_body: response} =
               post(conn, ~p"/api/sign_in", %{
                 "email" => "user_1@example.com",
                 "password" => "asdfasdfasdf"
               })

      assert {:ok, %{"data" => %{"access_token" => _acess_token}}} = Jason.decode(response)
    end

    test "access_token has correct claims", %{conn: conn} do
      assert %{status: 200, resp_body: response} =
               post(conn, ~p"/api/sign_in", %{
                 "email" => "user_1@example.com",
                 "password" => "asdfasdfasdf"
               })

      {:ok, %{"data" => %{"access_token" => acess_token}}} = Jason.decode(response)

      assert {:ok, %{"sub" => user_id, "username" => username, "email" => email}} =
               Chatnix.Guardian.decode_and_verify(acess_token)

      user = Chatnix.Auth.get_user(%{id: user_id})
      assert username == user.username
      assert email == user.email
    end

    test "returns 401 for invalid params", %{conn: conn} do
      assert %{status: 401} =
               post(conn, ~p"/api/sign_in", %{
                 "email" => "userabcabc@example.com",
                 "password" => "asdfasdfasdf"
               })
    end
  end
end
