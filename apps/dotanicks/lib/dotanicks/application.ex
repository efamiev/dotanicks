defmodule Dotanicks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DNSCluster, query: Application.get_env(:dotanicks, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Dotanicks.PubSub},
      {Finch, name: DotanicksFinch}
      # Start a worker by calling: Dotanicks.Worker.start_link(arg)
      # {Dotanicks.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Dotanicks.Supervisor)
  end
end
