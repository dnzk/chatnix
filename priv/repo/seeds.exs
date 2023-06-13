# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Chatnix.Repo.insert!(%Chatnix.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Chatnix.{Auth, Conversation}

Auth.create_user(%{
  username: "user_1",
  email: "user_1@example.com",
  password: "asdfasdfasdf"
})

Conversation.create_room("Room 1")
