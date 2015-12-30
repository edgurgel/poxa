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
    children = [worker(Poxa.App, []),
                worker(GenEvent, [[name: Poxa.Event]])]
    supervise children, strategy: :one_for_one
  end
end

