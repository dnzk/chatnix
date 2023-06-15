defmodule Chatnix.Conversation do
  @moduledoc """
  Conversation context
  """
  alias Chatnix.Schemas.{Room, User}
  alias Chatnix.Repo

  @doc """
  Creates chat room.

  ## Parameters

    - name: The room's name
    - participants: List of map with `id` key for user ID
  """
  @spec create_room(%{
          required(:name) => String.t(),
          required(:participants) => list(%{id: integer()})
        }) :: {:ok, any} | {:error, any}
  def create_room(%{name: name, participants: participants}) do
    Repo.transaction(fn ->
      with {:ok, room} <- insert_room(name),
           {:ok, users} <- get_users(participants),
           {:ok, updated_room} <- associate_room_with_users(room, users) do
        updated_room
      else
        {:error, error} ->
          Repo.rollback(error)

        error ->
          Repo.rollback(error)
      end
    end)
  end

  @doc """
  Deletes a room.

  ## Parameters

    - id: Room ID to delete
  """
  @spec delete_room(integer()) :: {:ok, any} | {:error, any}
  def delete_room(id) do
    case Repo.get(Room, id) do
      nil -> {:error, "Room not found"}
      room -> Repo.delete(room)
    end
  end

  defp associate_room_with_users(%Room{} = room, users) do
    room
    |> Repo.preload(:users)
    |> Ecto.Changeset.change(%{})
    |> Ecto.Changeset.put_assoc(:users, users)
    |> Repo.update()
  end

  defp insert_room(name) do
    %{name: name}
    |> Room.insert_changeset()
    |> Repo.insert()
  end

  defp get_users(participants) do
    user_ids = Enum.map(participants, & &1.id)

    users =
      User
      |> User.get_all_by_id(user_ids)
      |> Repo.all()

    case users do
      [] -> {:error, "Users not found"}
      _ -> {:ok, users}
    end
  end
end
