defmodule Poxa.Adapter.GProc do
  @behaviour Poxa.Registry
  @moduledoc """
  """

  import :gproc

  def register(channel) do
    reg({:p, :l, {:pusher, channel}})
  end

  def register(channel, {user_id, user_info}) do
    reg({:p, :l, {:pusher, channel}}, {user_id, user_info})
  end

  def unregister(channel) do
    unreg({:p, :l, {:pusher, channel}});
  end

  def send_event(channel, {caller, message}) do
    :gproc.send({:p, :l, {:pusher, channel}}, {caller, message})
  end

  def send_event(channel, {caller, message, socket_id}) do
    :gproc.send({:p, :l, {:pusher, channel}}, {caller, message, socket_id})
  end

  def users(channel) do
    find_users(channel)
    |> Enum.map(fn {user_id, _} -> user_id end)
  end

  def user_count(channel) do
    find_users(channel)
    |> Enum.count
  end

  def occupied?(channel) do
    subscription_count(channel) != 0
  end

  def subscription_count(channel) do
    match = {{:p, :l, {:pusher, channel}}, :_, :_}
    select_count([{match, [], [true]}])
  end

  def subscribed?(channel, pid) do
    match = {{:p, :l, {:pusher, channel}}, pid, :_}
    select_count([{match, [], [true]}]) != 0
  end

  def channels(pid \\ :_) do
    match = {{:p, :l, {:pusher, :'$1'}}, pid, :_}
    select([{match, [], [:'$1']}]) |> Enum.uniq
  end

  def channel_data(channel) do
    for {_pid, {user_id, user_info}} <- lookup_values({:p, :l, {:pusher, channel}}) do
      {user_id, user_info}
    end |> Enum.uniq(fn {user_id, _} -> user_id end)
  end

  def connection_count(channel, user_id) do
    match = {{:p, :l, {:pusher, channel}}, :_, {user_id, :_}}
    select_count([{match, [], [true]}])
  end

  def in_presence_channel?(user_id, channel) do
    match = {{:p, :l, {:pusher, channel}}, :_, {user_id, :_}}
    :gproc.select_count([{match, [], [true]}]) != 0
  end

  def clean_up, do: goodbye

  defp find_users(channel) do
    match = {{:p, :l, {:pusher, channel}}, :_, :'$1'}
    :gproc.select([{match, [], [:'$1']}])
    |> Enum.uniq(fn {user_id, _} -> user_id end)
  end
end
