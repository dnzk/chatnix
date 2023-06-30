defmodule ChatnixWeb.RoomJSON do
  def get_users(%{users: users}) do
    %{data: %{users: users}}
  end

  def get_users(%{error: error}) do
    %{data: %{error: error}}
  end

  def init_conversation(%{room: room}) do
    %{data: %{room: room}}
  end

  def init_conversation(%{error: error}) do
    %{data: %{error: error}}
  end
end
