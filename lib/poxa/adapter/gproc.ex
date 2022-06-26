defmodule Poxa.Adapter.GProc do
  @moduledoc """
  Module that will enable using GProc as an adapter for Poxa registry.
  """

  @behaviour Poxa.Registry

  import :gproc
  require Ex2ms

  @impl true
  def register!(key) do
    reg({:p, :l, {:pusher, key}})
    :ok
  end

  @impl true
  def register!(key, value) do
    reg({:p, :l, {:pusher, key}}, value)
    :ok
  end

  @impl true
  def unregister!(key) do
    unreg({:p, :l, {:pusher, key}})
    :ok
  end

  @impl true
  def send!(message, channel, sender) do
    :gproc.send({:p, :l, {:pusher, channel}}, {sender, message})
  end

  @impl true
  def send!(message, channel, sender, socket_id) do
    :gproc.send({:p, :l, {:pusher, channel}}, {sender, message, socket_id})
  end

  @impl true
  def subscription_count(channel, pid \\ :_)

  def subscription_count(channel, pid) when is_pid(pid) or pid == :_ do
    Ex2ms.fun do
      {{:p, :l, {:pusher, ^channel}}, ^pid, _} -> true
    end
    |> select_count
  end

  def subscription_count(channel, user_id) do
    Ex2ms.fun do
      {{:p, :l, {:pusher, ^channel}}, _, {^user_id, _}} -> true
    end
    |> select_count
  end

  @impl true
  def presence_subscriptions(pid) do
    Ex2ms.fun do
      {{:p, :l, {:pusher, channel}}, ^pid, %{user_id: user_id}} -> {channel, user_id}
    end
    |> select
  end

  @impl true
  def channels() do
    Ex2ms.fun do
      {{:p, :l, {:pusher, channel}}, :_, _} -> channel
    end
    |> select
    |> Enum.uniq_by(& &1)
  end

  @impl true
  def unique_subscriptions(channel) do
    for {_pid, %{user_id: user_id, user_info: user_info}} <-
          lookup_values({:p, :l, {:pusher, channel}}),
        into: %{} do
      {user_id, user_info}
    end
  end

  @impl true
  def fetch(key) do
    get_value({:p, :l, {:pusher, key}})
  end

  @impl true
  def clean_up, do: goodbye()
end
