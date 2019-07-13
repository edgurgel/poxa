defmodule Poxa.WebHook.Supervisor do
  use Supervisor

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @doc """
  This supervisor will spawn a `Watcher` to monitor a handler for web hook events and a `GenServer` to dispatch the actual requests.
  """
  def init([]) do
    web_wook_dispatcher = worker(Poxa.WebHook.Dispatcher, [])
    web_wook_handler = worker(Poxa.WebHook.Handler, [])
    children = [web_wook_handler, web_wook_dispatcher]

    supervise(children, strategy: :one_for_one)
  end
end
