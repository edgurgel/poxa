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
    children = [worker(GenEvent, [[name: Poxa.Event]])]
    if web_hook do
      web_wook_worker = worker(Watcher, [Poxa.Event, Poxa.WebHook, []])
      children = children ++ [web_wook_worker]
    end
    supervise children, strategy: :one_for_one
  end
end

