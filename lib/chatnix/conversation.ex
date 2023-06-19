defmodule Chatnix.Conversation do
  @moduledoc """
  Conversation context
  """
  alias Chatnix.Schemas.{Room, User, Message, UsersRooms}
  alias Chatnix.Repo

  @typep id :: String.t() | integer()

  @doc """
  Creates chat room.

  ## Parameters

    - name: The room's name
    - participants: List of map with `id` key for user ID
  """
  @spec create_room(%{
          required(:name) => String.t(),
          required(:participants) => list(%{id: id()})
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
  @spec delete_room(id()) :: {:ok, any} | {:error, any}
  def delete_room(id) do
    case Repo.get(Room, id) do
      nil -> {:error, "Room not found"}
      room -> Repo.delete(room)
    end
  end

  @doc """
  Creates a message.

  ## Parameters

    - message: The message to create.
    - room_id: Room ID to send the message to.
    - sender_id: The ID of the user who sent the message.
  """
  @spec create_message(%{
          required(:message) => String.t(),
          required(:room_id) => id(),
          required(:sender_id) => id()
        }) :: {:ok, any} | {:error, any}
  def create_message(%{sender_id: sender_id, room_id: room_id, message: message}) do
    Repo.transaction(fn ->
      with {:ok, message} <- insert_message(message),
           {:ok, users_rooms} <- get_users_rooms(%{user_id: sender_id, room_id: room_id}),
           {:ok, updated_message} <- associate_message_with_users_rooms(message, users_rooms) do
        updated_message
      else
        {:error, error} ->
          Repo.rollback(error)

        error ->
          Repo.rollback(error)
      end
    end)
  end

  @doc """
  Deletes a message.

  ## Parameters

    - message_id: The message ID to delete.
    - user_id: The user ID who owns the message.
  """
  @spec delete_message(%{
          required(:message_id) => id(),
          required(:user_id) => id()
        }) :: {:ok, Ecto.Schema.t()} | {:error, any}
  def delete_message(%{user_id: user_id, message_id: message_id}) do
    Repo.transaction(fn ->
      with {:ok, user} <- get_user(user_id),
           {:ok, message} <- get_message(message_id),
           :ok <- message_belongs_to_user(user, message),
           {:ok, deleted_message} <- Repo.delete(message) do
        deleted_message
      else
        {:error, error} ->
          Repo.rollback(error)

        error ->
          Repo.rollback(error)
      end
    end)
  end

  @doc """
  Updates a message.

  ## Parameters

    - message_id: The message ID to update
    - user_id: The user ID that owns the message
    - message: The new message
  """
  @spec update_message(%{
          required(:message) => String.t(),
          required(:message_id) => id(),
          required(:user_id) => id()
        }) :: {:ok, Ecto.Schema.t()} | {:error, any}
  def update_message(%{user_id: user_id, message_id: message_id, message: content}) do
    Repo.transaction(fn ->
      with {:ok, user} <- get_user(user_id),
           {:ok, message} <- get_message(message_id),
           :ok <- message_belongs_to_user(user, message),
           {:ok, updated_message} <- attempt_update_message(message, content) do
        updated_message
      else
        {:error, error} ->
          Repo.rollback(error)

        error ->
          Repo.rollback(error)
      end
    end)
  end

  defp attempt_update_message(%Message{} = message, content) do
    message
    |> Message.changeset(%{content: content})
    |> Repo.update()
  end

  @doc """
  Gets a message.

  ## Parameters

    - THe message ID to get
  """
  @spec get_message(id()) :: {:error, String.t()} | {:ok, Ecto.Schema.t()}
  def get_message(message_id) do
    case Repo.get(Message, message_id) do
      nil -> {:error, "Message not found"}
      message -> {:ok, message}
    end
  end

  @doc """
  Gets a User.

  ## Parameters

    - user_id: The user's ID
  """
  @spec get_user(id()) :: {:ok, Ecto.Schema.t()} | {:error, any}
  def get_user(user_id) do
    case Repo.get(User, user_id) do
      nil -> {:error, "User not found"}
      user -> {:ok, user}
    end
  end

  defp message_belongs_to_user(
         %User{
           id: user_id
         },
         %Message{
           users_rooms_id: users_rooms_id
         }
       ) do
    with {:ok, users_rooms} <- get_users_rooms(users_rooms_id),
         true <- users_rooms.user_id === user_id do
      :ok
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp associate_message_with_users_rooms(%Message{} = message, %UsersRooms{} = users_rooms) do
    message
    |> Repo.preload(:users_rooms)
    |> Ecto.Changeset.change(%{})
    |> Ecto.Changeset.put_assoc(:users_rooms, users_rooms)
    |> Repo.update()
  end

  defp insert_message(content) do
    %{content: content}
    |> Message.insert_changeset()
    |> Repo.insert()
  end

  defp get_users_rooms(%{user_id: user_id, room_id: room_id}) do
    case Repo.get_by(UsersRooms, user_id: user_id, room_id: room_id) do
      nil -> {:error, "Conversation not found"}
      users_rooms -> {:ok, users_rooms}
    end
  end

  defp get_users_rooms(id) do
    case Repo.get(UsersRooms, id) do
      nil -> {:error, "Conversation not found"}
      users_rooms -> {:ok, users_rooms}
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
