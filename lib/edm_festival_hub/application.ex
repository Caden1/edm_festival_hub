defmodule EdmFestivalHub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EdmFestivalHubWeb.Telemetry,
      EdmFestivalHub.Repo,
      {DNSCluster, query: Application.get_env(:edm_festival_hub, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EdmFestivalHub.PubSub},
      # Start a worker by calling: EdmFestivalHub.Worker.start_link(arg)
      # {EdmFestivalHub.Worker, arg},
      # Start to serve requests, typically the last entry
      EdmFestivalHubWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EdmFestivalHub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EdmFestivalHubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
