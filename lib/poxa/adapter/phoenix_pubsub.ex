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

  @impl true
  @spec register!(binary | atom) :: :ok | {:error, any}
  def register!(key) do
    register!(key, nil)
  end

  @impl true
  @spec register!(any, nil | map) :: :ok | {:error, {:already_registered, pid}}
  def register!(key, value) do
    topic = topic(key)

    with {:registry, {:ok, _}} <-
           {:registry, Registry.register(@registry, {:pusher, key}, value)},
         {:tracker, {:ok, _}} <-
           {:tracker, Tracker.track(@tracker, self(), topic, key, value || %{})},
         :ok <- PubSub.subscribe(@pubsub, topic) do
      :ok
    else
      {:registry, error} ->
        error

      {:tracker, error} ->
        Registry.unregister(@registry, {:pusher, key})
        error

      {:error, reason} ->
        Registry.unregister(@registry, {:pusher, key})
        Tracker.untrack(@tracker, self(), topic, key)
        {:error, reason}
    end
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
    Poxa.Adapter.PhoenixPubSub.Tracker.subscription_count(channel)
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
    Poxa.Adapter.PhoenixPubSub.Tracker.channels()
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
    case Registry.values(@registry, {:pusher, key}, self()) do
      [] -> nil
      [value] -> value
    end
  end

  @impl true
  # goodbye()
  def clean_up, do: nil
end
