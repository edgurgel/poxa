defmodule Poxa.Registry do

  def subscribe(channel) do
    adapter.register(channel)
  end

  def subscribe(channel, {user_id, user_info}) do
    adapter.register(channel, {user_id, user_info})
  end

  def unsubscribe(channel) do
    adapter.unregister(channel)
  end

  def send_event(channel, {caller, message}) do
    adapter.send_event(channel, {caller, message})
  end

  def send_event(channel, {caller, message, socket_id}) do
    adapter.send_event(channel, {caller, message, socket_id})
  end

  def users(channel) do
    adapter.users(channel)
  end

  def user_count(channel) do
    adapter.user_count(channel)
  end

  def occupied?(channel) do
    adapter.occupied?(channel)
  end

  def subscription_count(channel) do
    adapter.subscription_count(channel)
  end

  def subscribed?(channel, pid) do
    adapter.subscribed?(channel, pid)
  end

  def channels(pid \\ :_) do
    adapter.channels(pid)
  end

  def channel_data(channel) do
    adapter.channel_data(channel)
  end

  def connection_count(channel, user_id) do
    adapter.connection_count(channel, user_id)
  end

  def in_presence_channel?(user_id, channel) do
    adapter.in_presence_channel?(user_id, channel)
  end

  def fetch_subscription(channel) do
    adapter.fetch_subscription(channel)
  end

  def clean_up do
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

  @callback in_presence_channel?(String.t, PID.t) :: boolean

  @callback fetch_subscription(String.t) :: any

  @callback clean_up() :: any


  defp adapter do
    adapter = Application.get_env(:poxa, :adapter)
    case adapter do
        "gproc" -> Poxa.Adapter.GProc
        _ -> raise "no adapter found"
    end
  end
end
