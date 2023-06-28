# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :chatnix, Chatnix.Guardian,
  issuer: "chatnix",
  secret_key: "664c9OeJYvhEVO4zd7jUUHoH3i/eEMuXfY9Zau7fNIJBlRNsFNmf5/O5T9hrBylm",
  ttl: {1, :day}

config :chatnix, env: Mix.env()

config :chatnix,
  ecto_repos: [Chatnix.Repo]

# Configures the endpoint
config :chatnix, ChatnixWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: ChatnixWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Chatnix.PubSub,
  live_view: [signing_salt: "txpJ91QU"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :chatnix, Chatnix.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
