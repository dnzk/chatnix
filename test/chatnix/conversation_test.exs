defmodule Chatnix.ConversationTest do
  @moduledoc """
  Conversation context test
  """
  use Chatnix.DataCase, async: true
  alias Chatnix.Conversation
  alias Chatnix.Repo
  alias Chatnix.Schemas.Room
  alias Chatnix.TestHelpers.EctoChangeset

  describe "&create_room/1" do
    test "returns error when room name is taken" do
      assert {:error, changeset} =
               Conversation.create_room(%{
                 name: "Room 1",
                 participants: [
                   %{id: 1},
                   %{id: 2}
                 ]
               })

      assert EctoChangeset.fetch_error_constraint(changeset, :name, :constraint) === :unique
    end

    test "returns error when room name is shorter than 3" do
      assert {:error, changeset} =
               Conversation.create_room(%{name: "22", participants: [%{id: 1}]})

      assert EctoChangeset.fetch_error_constraint(changeset, :name, :validation) === :length
      assert EctoChangeset.fetch_error_constraint(changeset, :name, :kind) === :min
    end

    test "does not create room when user IDs are invalid" do
      assert {:error, _error} =
               Conversation.create_room(%{
                 name: "Room 2",
                 participants: [
                   %{id: 100},
                   %{id: 200}
                 ]
               })

      new_room = Repo.get_by(Room, name: "Room 2")
      assert is_nil(new_room)
    end

    test "creates room with valid params" do
      assert {:ok, _room} =
               Conversation.create_room(%{
                 name: "Room 2",
                 participants: [
                   %{id: 1},
                   %{id: 2}
                 ]
               })
    end
  end

  describe "&delete_room/1" do
    test "returns error when room id does not exist" do
      assert {:error, _} = Conversation.delete_room(300)
    end

    test "deletes room when room id is valid" do
      assert {:ok, _} = Conversation.delete_room(1)

      assert is_nil(Repo.get(Room, 1))
    end
  end
end
