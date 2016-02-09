defmodule Poxa.Registry do

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

  def occupied?(channel) do
    adapter = get_adapter
    adapter.occupied?(channel)
  end

  def subscription_count(channel) do
    adapter = get_adapter
    adapter.subscription_count(channel)
  end

  def subscribed?(channel, pid) do
    adapter = get_adapter
    adapter.subscribed?(channel, pid)
  end

  def channels(pid \\ :_) do
    adapter = get_adapter
    adapter.channels(pid)
  end

  def channel_data(channel) do
    adapter = get_adapter
    adapter.channel_data(channel)
  end

  def connection_count(channel, user_id) do
    adapter = get_adapter
    adapter.connection_count(channel, user_id)
  end

  def clean_up do
    adapter = get_adapter
    adapter.clean_up
  end

  @callback register(String.t) :: any
  @callback register(String.t, Map.t) :: any

  @callback unregister(String.t) :: any

  @callback send_event(String.t, Map.t) :: any

  @callback users(String.t) :: Map.t

  @callback user_count(String.t) :: Integer.t

  @callback occupied?(String.t) :: boolean

  @callback subscription_count(String.t) :: Integer.t

  @callback subscribed?(String.t, PID.t) :: boolean

  @callback channels(pid) :: Map.t

  @callback channel_data(String.t) :: Map.t

  @callback connection_count(String.t, Integer.t) :: Integer.t

  @callback clean_up() :: any


  defp get_adapter do
    adapter = Application.get_env(:poxa, :adapter)
    case adapter do
        "gproc" -> Poxa.Adapter.GProc
        _ -> raise "no adapter found"
    end
  end
end
