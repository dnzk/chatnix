defmodule Chatnix.ConversationTest do
  @moduledoc """
  Conversation context test
  """
  use Chatnix.DataCase, async: true
  alias Chatnix.Conversation
  alias Chatnix.TestHelpers.EctoChangeset

  describe "&create_room/1" do
    test "returns error when room name is taken" do
      assert {:error, changeset} = Conversation.create_room("Room 1")
      assert EctoChangeset.fetch_error_constraint(changeset, :name, :constraint) === :unique
    end

    test "returns error when room name is shorter than 3" do
      assert {:error, changeset} = Conversation.create_room("22")
      assert EctoChangeset.fetch_error_constraint(changeset, :name, :validation) === :length
      assert EctoChangeset.fetch_error_constraint(changeset, :name, :kind) === :min
    end

    test "creates room with valid params" do
      assert {:ok, _room} = Conversation.create_room("Room 2")
    end
  end
end
