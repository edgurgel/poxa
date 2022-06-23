defmodule Poxa.Adapter.PhoenixPubSub.Supervisor do
  use Supervisor

  @doc false
  def start_link(_) do
    Supervisor.start_link(__MODULE__, [])
  end

  @impl true
  def init(_options) do
    children = [
      {Registry,
       keys: :duplicate,
       name: Poxa.Adapter.PhoenixPubSub.Registry,
       partitions: System.schedulers_online()},
      {Phoenix.PubSub, [name: Poxa.Adapter.PhoenixPubSub.PubSub]},
      {Poxa.Adapter.PhoenixPubSub.Tracker, [pubsub_server: Poxa.Adapter.PhoenixPubSub.PubSub]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
