defmodule Poxa.Adapter.PhoenixPubSub do
  @moduledoc """
  Module that will enable using Phoenix.PubSub PG2 as an adapter for Poxa registry.
  """

  @behaviour Poxa.Registry

  alias Phoenix.PubSub
  alias Phoenix.Tracker
  require Ex2ms

  @registry Poxa.Adapter.PhoenixPubSub.Registry
  @tracker Poxa.Adapter.PhoenixPubSub.Tracker
  @pubsub Poxa.Adapter.PhoenixPubSub.PubSub

  @impl true
  def child_spec(options) do
    Poxa.Adapter.PhoenixPubSub.Supervisor.child_spec(options)
  end

  defp topic(key), do: "pusher:#{key}"
  # defp channels_topic(pid), do: "channels:#{inspect(pid)}"

  @impl true
  def register!(key) do
    topic = topic(key)

    with {:ok, _} <- Registry.register(@registry, {:pusher, key}, nil),
         {:ok, _} <- Tracker.track(@tracker, self(), topic, key, %{}),
         :ok <- PubSub.subscribe(@pubsub, topic),
         do: :ok
  end

  @impl true
  def register!(key, value) do
    topic = topic(key)
    # value might be {user_id, user_info}. Must transform into a map
    {:ok, _} = Registry.register(@registry, {:pusher, key}, value)
    Tracker.track(@tracker, self(), topic, key, value)
    PubSub.subscribe(@pubsub, topic)
  end

  @impl true
  def unregister!(key) do
    topic = topic(key)
    Registry.unregister(@registry, {:pusher, key})
    Tracker.untrack(@tracker, self(), topic, key)
    PubSub.unsubscribe(@pubsub, topic)
  end

  @impl true
  def send!(message, channel, sender) do
    PubSub.broadcast(@pubsub, topic(channel), {sender, message})
  end

  @impl true
  def send!(message, channel, sender, socket_id) do
    PubSub.broadcast(@pubsub, topic(channel), {sender, message, socket_id})
  end

  @impl true
  def subscription_count(channel) do
    # Replace this with Tracker ets data
    Tracker.list(@tracker, topic(channel)) |> Enum.count()
  end

  @impl true
  def subscription_count(channel, pid) when is_pid(pid) do
    Registry.keys(@registry, pid)
    |> Enum.count(&(&1 == {:pusher, channel}))
  end

  def subscription_count(channel, user_id) do
    Tracker.list(@tracker, topic(channel))
    |> Enum.count(fn {_key, value} -> value[:user_id] == user_id end)
  end

  @impl true
  def presence_subscriptions(pid) do
    spec =
      Ex2ms.fun do
        {{:pusher, channel}, ^pid, %{user_id: user_id}} ->
          {channel, user_id}
      end

    Registry.select(@registry, spec)
  end

  @impl true
  def channels() do
    # ETS from Tracker
    raise "Missing"
  end

  @impl true
  def unique_subscriptions(channel) do
    for {_key, %{user_id: user_id, user_info: user_info}} <-
          Tracker.list(@tracker, topic(channel)),
        into: %{} do
      {user_id, user_info}
    end
  end

  @impl true
  def fetch(key) do
    # get_value({:p, :l, {:pusher, key}})
  end

  @impl true
  # goodbye()
  def clean_up, do: nil
end
