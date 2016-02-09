defmodule Poxa.Registry do
  use Behaviour

  def subscribe(channel) do
    adapter = get_adapter
    adapter.register(channel)
  end

  def subscribe(channel, {user_id, user_info}) do
    adapter = get_adapter
    adapter.register(channel, {user_id, user_info})
  end

  def unsubscribe(channel) do
    adapter = get_adapter
    adapter.unregister(channel)
  end

  defcallback register(String.t) :: any
  defcallback register(String.t, Map.t) :: any

  defcallback unregister(String.t) :: any

  defp get_adapter do
    adapter = Application.get_env(:poxa, :adapter)
    case adapter do
        "gproc" -> Poxa.Adapter.GProc
        _ -> raise "no adapter found"
    end
  end
end
