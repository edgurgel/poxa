defmodule Poxa.SubscriptionHandler do
  @moduledoc """
  This module will be responsible for notifying when channels get occupied or vacated.
  """

  use GenServer
  alias Poxa.Channel
  import Poxa.Event, only: [notify: 2]

  @doc false
  def start_link(), do: GenServer.start_link(__MODULE__, [])

  @doc false
  def init(_) do
    Poxa.Event.subscribe()
    {:ok, []}
  end

  @doc false
  def handle_info({:internal_event, event}, state) do
    handle_event(event)
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp handle_event(%{event: :disconnected, channels: channels, socket_id: socket_id}) do
    for c <- channels, !Channel.occupied?(c) do
      notify(:channel_vacated, %{channel: c, socket_id: socket_id})
    end
  end

  defp handle_event(%{event: :subscribed, channel: channel, socket_id: socket_id}) do
    if Channel.subscription_count(channel) == 1 do
      notify(:channel_occupied, %{channel: channel, socket_id: socket_id})
    end
  end

  defp handle_event(%{event: :unsubscribed, channel: channel, socket_id: socket_id}) do
    unless Channel.occupied?(channel) do
      notify(:channel_vacated, %{channel: channel, socket_id: socket_id})
    end
  end

  defp handle_event(_), do: :ok
end
