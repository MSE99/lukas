defmodule Lukas.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LukasWeb.Telemetry,
      # Start the Ecto repository
      Lukas.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Lukas.PubSub},
      # Start Finch
      {Finch, name: Lukas.Finch},
      # Start the Endpoint (http/https)
      LukasWeb.Endpoint
      # Start a worker by calling: Lukas.Worker.start_link(arg)
      # {Lukas.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lukas.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LukasWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
