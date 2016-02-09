defmodule Poxa.Registry do
  use Behaviour

  def subscribe(channel) do
    adapter = get_adapter
    adapter.register(channel)
  end

  def unsubscribe(channel) do
    adapter = get_adapter
    adapter.unregister(channel)
  end

  defcallback register(String.t) :: any

  defcallback unregister(String.t) :: any

  defp get_adapter do
    adapter = Application.get_env(:adapter)
    case adapter do
        "gproc" -> Poxa.Adapter.GProc
        _ -> raise "no adapter found"
    end
  end
end
