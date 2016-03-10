defmodule Poxa.Supervisor do
  use Supervisor

  @doc false
  def start_link do
    :supervisor.start_link({:local, __MODULE__}, __MODULE__, [])
  end

  @doc """
  The supervisor will spawn a GenEvent named Poxa.Event
  """
  def init([]) do
    {:ok, web_hook} = Application.fetch_env(:poxa, :web_hook)
    event_worker = worker(GenEvent, [[name: Poxa.Event]])
    subscription_worker = worker(Watcher, [Poxa.Event, Poxa.SubscriptionHandler, []], [id: Poxa.SubscriptionHandler])
    children = [event_worker, subscription_worker]
    if web_hook do
      web_wook_watcher = worker(Watcher, [Poxa.Event, Poxa.WebHook.Handler, []], [id: Poxa.WebHook.Handler])
      web_wook_dispatcher = worker(Poxa.WebHook.Dispatcher, [])
      children = children ++ [web_wook_watcher, web_wook_dispatcher]
    end
    supervise children, strategy: :one_for_one
  end
end

