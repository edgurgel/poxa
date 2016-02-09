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

  def send_event(channel, {caller, message}) do
    adapter = get_adapter
    adapter.send_event(channel, {caller, message})
  end

  def send_event(channel, {caller, message, socket_id}) do
    adapter = get_adapter
    adapter.send_event(channel, {caller, message, socket_id})
  end

  def users(channel) do
    adapter = get_adapter
    adapter.users(channel)
  end

  def user_count(channel) do
    adapter = get_adapter
    adapter.user_count(channel)
  end

  defcallback register(String.t) :: any
  defcallback register(String.t, Map.t) :: any

  defcallback unregister(String.t) :: any

  defcallback send_event(String.t, Map.t) :: any

  defcallback users(String.t) :: any
  defcallback user_count(String.t) :: any

  defp get_adapter do
    adapter = Application.get_env(:poxa, :adapter)
    case adapter do
        "gproc" -> Poxa.Adapter.GProc
        _ -> raise "no adapter found"
    end
  end
end
