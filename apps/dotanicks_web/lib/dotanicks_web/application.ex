defmodule DotanicksWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :logger.add_handlers(:dotanicks)

    children = [
      DotanicksWeb.Telemetry,
      # Start a worker by calling: DotanicksWeb.Worker.start_link(arg)
      # {DotanicksWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      DotanicksWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DotanicksWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DotanicksWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
