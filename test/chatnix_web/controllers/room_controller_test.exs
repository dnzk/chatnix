defmodule ChatnixWeb.RoomControllerTest do
  @moduledoc """
  Room controller test
  """
  use ChatnixWeb.ConnCase, async: true

  describe "get_users" do
    test "returns error for unauthenticated request", %{conn: conn} do
      assert %{status: 401} = get(conn, ~p"/api/users")
    end

    test "returns users for authenticated request", %{conn: conn} do
      %{resp_body: response} =
        post(conn, ~p"/api/sign_in", %{
          "email" => "user_1@example.com",
          "password" => "asdfasdfasdf"
        })

      {:ok, %{"data" => %{"access_token" => access_token}}} = Jason.decode(response)

      r =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> get(~p"/api/users")

      assert %{status: 200, resp_body: response} = r
      {:ok, %{"data" => %{"users" => users}}} = Jason.decode(response)
      assert match?([%{"email" => _, "id" => _, "username" => _} | _], users)
    end
  end

  describe "init_room" do
    test "returns error for unauthenticated request", %{conn: conn} do
      assert %{status: 401} =
               post(conn, ~p"/api/init_conversation", %{
                 "id" => 1
               })
    end

    test "returns unprocessable entity for invalid params", %{conn: conn} do
      %{resp_body: response} =
        post(conn, ~p"/api/sign_in", %{
          "email" => "user_1@example.com",
          "password" => "asdfasdfasdf"
        })

      {:ok, %{"data" => %{"access_token" => access_token}}} = Jason.decode(response)

      r =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> post(~p"/api/init_conversation", %{
          "id" => 1
        })

      assert %{status: 422} = r
    end

    test "returns room with status 200 for valid params", %{conn: conn} do
      %{resp_body: response} =
        post(conn, ~p"/api/sign_in", %{
          "email" => "user_1@example.com",
          "password" => "asdfasdfasdf"
        })

      {:ok, %{"data" => %{"access_token" => access_token}}} = Jason.decode(response)

      r =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> post(~p"/api/init_conversation", %{
          "id" => 3
        })

      assert %{status: 200, resp_body: _response} = r
    end
  end
end
