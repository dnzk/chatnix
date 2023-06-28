defmodule Chatnix.Seeder.DatabaseSeeder do
  @moduledoc """
  Database seeder
  """

  def run() do
    :chatnix
    |> Application.get_env(:env, :dev)
    |> seed()
  end

  defp seed(:dev) do
    Chatnix.Seeder.DevSeeder.seed()
  end

  defp seed(:test) do
    Chatnix.Seeder.TestSeeder.seed()
  end

  defp seed(env) do
    raise "Seeder for #{env} is not implemented"
  end
end
