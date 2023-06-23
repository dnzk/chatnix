defmodule Chatnix.Conversation do
  @moduledoc """
  Conversation context
  """
  alias Chatnix.Schemas.RoomAccess
  alias Chatnix.Schemas.{Room, User, Message, UsersRooms}
  alias Chatnix.Repo

  @typep id :: String.t() | integer()

  @doc """
  Creates chat room.

  ## Parameters

    - name: The room's name
    - admin: The room creator
    - participants: List of map with `id` key for user ID
    - is_private: Whether the room is private or public
  """
  @spec create_room(
          %{
            required(:name) => String.t(),
            required(:participants) => list(%{id: id()}),
            required(:admin) => %{id: id()}
          },
          is_dm_room: boolean(),
          is_private: boolean()
        ) :: {:ok, any} | {:error, any}
  def create_room(
        %{
          name: name,
          participants: participants,
          admin: admin
        },
        options \\ []
      ) do
    case Keyword.get(options, :is_dm_room, false) do
      true ->
        Repo.transaction(fn ->
          with 2 <- length(participants),
               false <- dm_room_exists?(participants),
               users <- get_users(participants),
               {:ok, room} <-
                 insert_room(generate_dm_room_name(users), true, true),
               {:ok, updated_room} <- associate_room_with_users(room, users) do
            updated_room
          else
            {:error, error} ->
              Repo.rollback(error)

            error when is_integer(error) ->
              Repo.rollback("DM room has to contain exactly 2 participants")

            error ->
              Repo.rollback(error)
          end
        end)

      _ ->
        is_private = Keyword.get(options, :is_private, false)

        Repo.transaction(fn ->
          with {:ok, admin} <- get_user(admin.id),
               {:ok, room} <- insert_room(name, is_private, false),
               users <- get_users(participants),
               {:ok, updated_room} <- associate_room_with_users(room, [admin | users]),
               {:ok, _updated_access_rights} <-
                 create_access_right(admin, room, %{is_admin: true}) do
            updated_room
          else
            {:error, error} ->
              Repo.rollback(error)

            error ->
              Repo.rollback(error)
          end
        end)
    end
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
  Get all rooms.

  """
  @spec get_all_rooms() :: {:ok, [Room.t()]}
  def get_all_rooms() do
    {:ok, Repo.all(Room)}
  end

  @doc """
  Adds users to room.

  ## Parameters

    - admin: Map containing id key for the admin's ID
    - room: Map containing id key for the room's ID
    - users: List of map containing id key for the user's ID

  ## Examples

    iex> Conversation.add_users_to_room(%{admin: %{id: 1}, room: %{id: 1}, users: [%{id: 2}, %{id: 3}]})
  """
  @spec add_users_to_room(%{
          required(:admin) => %{
            required(:id) => id()
          },
          required(:room) => %{
            required(:id) => id()
          },
          :users =>
            list(%{
              required(:id) => id()
            })
        }) :: {:ok, any} | {:error, any}
  def add_users_to_room(%{
        admin: %{id: admin_id},
        users: users,
        room: %{id: room_id}
      }) do
    Repo.transaction(fn ->
      with {:ok, admin} <- get_user(admin_id),
           users <- get_users(users),
           {:ok, room} <- get_room(room_id),
           true <- room_belongs_to_admin(room, admin),
           {:ok, updated_rooms} <- associate_room_with_users(room, users) do
        updated_rooms
      else
        {:error, error} ->
          Repo.rollback(error)

        error ->
          Repo.rollback(error)
      end
    end)
  end

  @doc """
  Removes users from room.

  ## Parameteres

    - admin: Map containing id key for admin ID
    - room: Map containing id key for room ID
    - users: List of users map containing id key for user ID
  """
  @spec remove_users_from_room(%{
          required(:admin) => %{
            required(:id) => id()
          },
          required(:room) => %{
            required(:id) => id()
          },
          required(:users) =>
            list(%{
              required(:id) => id()
            })
        }) :: {:ok, any} | {:error, any}
  def remove_users_from_room(%{
        admin: %{id: admin_id},
        room: %{id: room_id},
        users: users
      }) do
    Repo.transaction(fn ->
      with {:ok, admin} <- get_user(admin_id),
           users <- get_users(users),
           {:ok, room} <- get_room(room_id),
           true <- room_belongs_to_admin(room, admin) do
        disassociate_room_with_users(room, users)
      else
        {:error, error} ->
          Repo.rollback(error)

        error ->
          Repo.rollback(error)
      end
    end)
  end

  @doc """
  Sends message to room.

  ## Parameters

    - message: The message to send to room.
    - room: Map containing id key for the room ID.
    - sender: Map containing id key for the sender ID>
  """
  @spec send_message_to_room(%{
          required(:message) => String.t(),
          required(:room) => %{
            required(:id) => id()
          },
          required(:sender) => %{
            required(:id) => id()
          }
        }) :: {:ok, any()} | {:error, any()}
  def send_message_to_room(%{
        sender: %{id: sender_id},
        room: %{id: room_id},
        message: content
      }) do
    Repo.transaction(fn ->
      with {:ok, _sender} <- get_user(sender_id),
           {:ok, _room} <- get_room(room_id),
           {:ok, message} <-
             create_message(%{room_id: room_id, sender_id: sender_id, message: content}) do
        message
      else
        {:error, error} -> Repo.rollback(error)
        error -> Repo.rollback(error)
      end
    end)
  end

  @doc """
  Read messages in a room.

  ## Parameters

    - room: Map containing id key for the room ID
    - user: Map containing id key for the user ID
  """
  @spec read_messages_in_room(%{
          required(:room) => %{
            required(:id) => id()
          },
          required(:user) => %{
            required(:id) => id()
          }
        }) :: {:ok, any()} | {:error, any()}
  def read_messages_in_room(%{
        user: %{id: user_id},
        room: %{id: room_id}
      }) do
    if user_belongs_to_room(%{user_id: user_id, room_id: room_id}) do
      {:ok, get_messages_by_room(room_id)}
    else
      case get_room(room_id) do
        {:ok, room} -> attempt_read_messages(room)
        error -> error
      end
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

  defp generate_dm_room_name([%User{username: username} | users]) do
    generate_dm_room_name(users, username)
  end

  defp generate_dm_room_name([%User{username: username} | []], result) do
    "#{result}_#{username}"
  end

  defp dm_room_exists?(participants) do
    participants
    |> Enum.map(& &1.id)
    |> Room.query_dm_room()
    |> Repo.one()
    |> Kernel.==(length(participants))
  end

  defp attempt_read_messages(%Room{is_private: false, id: room_id}) do
    {:ok, get_messages_by_room(room_id)}
  end

  defp attempt_read_messages(%Room{is_private: true}) do
    {:error, "Room is private"}
  end

  defp get_messages_by_room(room_id) do
    Message
    |> Message.get_by_room(room_id)
    |> Repo.all()
  end

  defp get_room(room_id) do
    case Repo.get(Room, room_id) do
      nil -> {:error, "Room not found"}
      room -> {:ok, room}
    end
  end

  defp room_belongs_to_admin(%Room{id: room_id}, %User{id: admin_id}) do
    users_rooms = Repo.get_by(UsersRooms, user_id: admin_id, room_id: room_id)

    case Repo.get_by(RoomAccess, users_rooms_id: users_rooms.id) do
      nil -> false
      room_access -> room_access.is_admin
    end
  end

  defp create_access_right(
         %User{id: user_id},
         %Room{id: room_id},
         %{is_admin: _is_admin} = params
       ) do
    Repo.transaction(fn ->
      with {:ok, access_right} <- attempt_insert_room_access(params),
           {:ok, users_rooms} <- get_users_rooms(%{user_id: user_id, room_id: room_id}),
           {:ok, updated_access_right} <-
             associate_access_right_with_users_rooms(access_right, users_rooms) do
        updated_access_right
      else
        {:error, error} -> Repo.rollback(error)
        error -> Repo.rollback(error)
      end
    end)
  end

  defp attempt_insert_room_access(%{is_admin: _is_admin} = params) do
    %RoomAccess{}
    |> RoomAccess.changeset(params)
    |> Repo.insert()
  end

  defp associate_access_right_with_users_rooms(
         %RoomAccess{} = room_access,
         %UsersRooms{} = users_rooms
       ) do
    room_access
    |> Repo.preload(:users_rooms)
    |> Ecto.Changeset.change(%{})
    |> Ecto.Changeset.put_assoc(:users_rooms, users_rooms)
    |> Repo.update()
  end

  defp attempt_update_message(%Message{} = message, content) do
    message
    |> Message.changeset(%{content: content})
    |> Repo.update()
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

  defp user_belongs_to_room(%{user_id: _user_id, room_id: _room_id} = params) do
    case get_users_rooms(params) do
      {:ok, _} -> true
      _ -> false
    end
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
    room = Repo.preload(room, :users)

    room
    |> Ecto.Changeset.change(%{})
    |> Ecto.Changeset.put_assoc(:users, deduplicate_users(room.users, users))
    |> Repo.update()
  end

  defp disassociate_room_with_users(%Room{id: room_id}, users) do
    users_id = Enum.map(users, & &1.id)

    UsersRooms
    |> UsersRooms.get_by_room_and_users(room_id, users_id)
    |> Repo.delete_all()
  end

  defp deduplicate_users(existing_users, new_users) do
    existing_ids = Enum.map(existing_users, & &1.id)

    new_users
    |> Enum.filter(fn %{id: id} -> !Enum.member?(existing_ids, id) end)
    |> Kernel.++(existing_users)
  end

  defp insert_room(name, is_private, is_dm_room) do
    %{name: name, is_private: is_private, is_dm_room: is_dm_room}
    |> Room.insert_changeset()
    |> Repo.insert()
  end

  defp get_users(participants) do
    user_ids = Enum.map(participants, & &1.id)

    User
    |> User.get_all_by_id(user_ids)
    |> Repo.all()
  end
end
