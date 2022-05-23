defmodule Poxa.WebHook.Supervisor do
  use Supervisor

  @doc false
  def start_link(_) do
    Supervisor.start_link(__MODULE__, [])
  end

  @doc """
  This supervisor will spawn a `Watcher` to monitor a handler for web hook events and a `GenServer` to dispatch the actual requests.
  """
  def init([]) do
    children = [Poxa.WebHook.Dispatcher, Poxa.WebHook.Handler]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
