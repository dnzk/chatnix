defmodule ChatnixWeb.RoomJSON do
  def get_users(%{users: users}) do
    %{data: %{users: users}}
  end

  def get_users(%{error: error}) do
    %{data: %{error: error}}
  end

  def get_rooms(%{rooms: rooms}) do
    %{data: %{rooms: rooms}}
  end

  def get_rooms(%{error: error}) do
    %{data: %{error: error}}
  end

  def init_conversation(%{room: room}) do
    %{data: %{room: room}}
  end

  def init_conversation(%{error: error}) do
    %{data: %{error: error}}
  end

  def create_new_room(%{room: room}) do
    %{data: %{room: room}}
  end

  def create_new_room(%{error: error}) do
    %{data: %{error: error}}
  end
end
