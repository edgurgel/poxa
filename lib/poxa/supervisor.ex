defmodule Poxa.Supervisor do
  use Supervisor

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @doc """
  The supervisor will spawn a `GenEvent` named `Poxa.Event` and also a `Watcher`
  to monitor a `Poxa.SubscriptionHandler`. If the web hook URL is configured,
  it will also spawn a supervisor to take care of the processes related to web
  hooks.
  """
  def init([]) do
    {:ok, web_hook} = Application.fetch_env(:poxa, :web_hook)
    event_worker = worker(GenEvent, [[name: Poxa.Event]])
    subscription_worker = worker(Watcher, [Poxa.Event, Poxa.SubscriptionHandler, []])
    children = [event_worker, subscription_worker]
    children = if web_hook do
                 web_wook_supervisor = worker(Poxa.WebHook.Supervisor, [])
                 children ++ [web_wook_supervisor]
               else
                 children
               end
    supervise children, strategy: :one_for_one
  end
end

