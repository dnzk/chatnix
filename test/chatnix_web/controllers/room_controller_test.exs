defmodule ChatnixWeb.RoomControllerTest do
  @moduledoc """
  Room controller test
  """
  use ChatnixWeb.ConnCase, async: true
  alias Chatnix.Schemas.{UsersRooms, Room, RoomAccess}
  alias Chatnix.{Auth, Repo, Guardian}

  setup do
    {:ok, user} = Auth.authenticate_user(%{email: "user_1@example.com", password: "asdfasdfasdf"})
    {:ok, access_token, _claims} = Guardian.encode_and_sign(user)
    %{access_token: access_token, current_user: user}
  end

  describe "get_users" do
    test "returns error for unauthenticated request", %{conn: conn} do
      assert %{status: 401} = get(conn, ~p"/api/users")
    end

    test "returns users for authenticated request", %{conn: conn, access_token: access_token} do
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

    test "returns unprocessable entity for invalid params", %{
      conn: conn,
      access_token: access_token
    } do
      r =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> post(~p"/api/init_conversation", %{
          "id" => 1
        })

      assert %{status: 422} = r
    end

    test "returns room with status 200 for valid params", %{
      conn: conn,
      access_token: access_token
    } do
      r =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> post(~p"/api/init_conversation", %{
          "id" => 3
        })

      assert %{status: 200, resp_body: _response} = r
    end

    test "returns room with status 200 for room_id params", %{
      conn: conn,
      access_token: access_token
    } do
      r =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> post(~p"/api/init_conversation", %{
          "room_id" => 1
        })

      assert %{status: 200, resp_body: _response} = r
    end
  end

  describe "create_new_room" do
    test "returns 401 for unauthenticated user", %{conn: conn} do
      assert %{status: 401} = post(conn, ~p"/api/create_new_room", %{})
    end

    test "return 422 for invalid params", %{conn: conn, access_token: access_token} do
      r =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> post(~p"/api/create_new_room", %{})

      assert %{status: 422} = r
    end

    test "returns room with status 200 for valid params", %{
      conn: conn,
      access_token: access_token
    } do
      r =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> post(~p"/api/create_new_room", %{
          "name" => "Room name test",
          "participants" => [%{"id" => 2}, %{"id" => 3}],
          "is_private" => true
        })

      assert %{status: 200, resp_body: response} = r
      {:ok, %{"data" => %{"room" => %{"id" => id}}}} = Jason.decode(response)

      created_room = Repo.get(Room, id)

      assert created_room.is_private
      assert !is_nil(Repo.get_by(UsersRooms, user_id: 2, room_id: id))
      assert !is_nil(Repo.get_by(UsersRooms, user_id: 3, room_id: id))
    end

    test "current user becomes the admin of the room", %{
      conn: conn,
      access_token: access_token,
      current_user: current_user
    } do
      r =
        conn
        |> put_req_header("authorization", "Bearer #{access_token}")
        |> post(~p"/api/create_new_room", %{
          "name" => "Room name test",
          "participants" => [%{"id" => 2}],
          "is_private" => false
        })

      %{resp_body: response} = r
      {:ok, %{"data" => %{"room" => %{"id" => id}}}} = Jason.decode(response)

      ur = Repo.get_by(UsersRooms, user_id: current_user.id, room_id: id)
      ra = Repo.get_by(RoomAccess, users_rooms_id: ur.id)
      assert ra.is_admin
    end
  end
end
