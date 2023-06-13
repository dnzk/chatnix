defmodule Chatnix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ChatnixWeb.Telemetry,
      # Start the Ecto repository
      Chatnix.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Chatnix.PubSub},
      # Start Finch
      {Finch, name: Chatnix.Finch},
      # Start the Endpoint (http/https)
      ChatnixWeb.Endpoint
      # Start a worker by calling: Chatnix.Worker.start_link(arg)
      # {Chatnix.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chatnix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChatnixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
