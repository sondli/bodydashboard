defmodule Bodydashboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BodydashboardWeb.Telemetry,
      Bodydashboard.Repo,
      {DNSCluster, query: Application.get_env(:bodydashboard, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Bodydashboard.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Bodydashboard.Finch},
      # Start a worker by calling: Bodydashboard.Worker.start_link(arg)
      # {Bodydashboard.Worker, arg},
      # Start to serve requests, typically the last entry
      BodydashboardWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bodydashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BodydashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
