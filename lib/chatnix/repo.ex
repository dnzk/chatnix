defmodule Chatnix.Repo do
  use Ecto.Repo,
    otp_app: :chatnix,
    adapter: Ecto.Adapters.Postgres
end
