defmodule Poxa.SubscriptionHandler do
  @moduledoc """
  This module will be responsible for notifying when channels get occupied or vacated.
  """

  use GenEvent
  alias Poxa.Channel
  import Poxa.Event, only: [notify: 2]

  def handle_event(%{event: :disconnected, channels: channels, socket_id: socket_id}, []) do
    for c <- channels, !Channel.occupied?(c) do
      notify(:channel_vacated, %{channel: c, socket_id: socket_id})
    end
    {:ok, []}
  end

  def handle_event(%{event: :subscribed, channel: channel, socket_id: socket_id}, []) do
    if Channel.subscription_count(channel) == 1 do
      notify(:channel_occupied, %{channel: channel, socket_id: socket_id})
    end
    {:ok, []}
  end

  def handle_event(%{event: :unsubscribed, channel: channel, socket_id: socket_id}, []) do
    unless Channel.occupied?(channel) do
      notify(:channel_vacated, %{channel: channel, socket_id: socket_id})
    end
    {:ok, []}
  end

  def handle_event(_, []), do: {:ok, []}
end
