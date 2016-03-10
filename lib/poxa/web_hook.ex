defmodule Poxa.WebHook do
  @moduledoc """
  This module is a event handler that deals with events as they happen 
  and then adds them to the web hook event table.
  """
  use GenEvent
  alias Poxa.WebHookEvent
  alias Poxa.WebHookEventTable

  @delay 1500

  @doc false
  def init(_), do: {:ok, nil}

  @doc false
  def handle_event(%{event: :channel_vacated, channel: channel}, state) do
    WebHookEvent.channel_vacated(channel) |> WebHookEventTable.insert(@delay)
    {:ok, state}
  end

  def handle_event(%{event: :channel_occupied, channel: channel}, state) do
    WebHookEvent.channel_occupied(channel) |> WebHookEventTable.insert
    {:ok, state}
  end

  def handle_event(%{event: :member_added, channel: channel, user_id: user_id}, state) do
    WebHookEvent.member_added(channel, user_id) |> WebHookEventTable.insert
    {:ok, state}
  end

  def handle_event(%{event: :member_removed, channel: channel, user_id: user_id}, state) do
    WebHookEvent.member_removed(channel, user_id) |> WebHookEventTable.insert(@delay)
    {:ok, state}
  end

  def handle_event(%{event: :client_event_message, socket_id: socket_id, channels: channels, name: name, data: data}, state) do
    for c <- channels do
      WebHookEvent.client_event(c, name, data, socket_id, nil)
    end |> WebHookEventTable.insert
    {:ok, state}
  end

  # Events that cannot trigger any webhook event
  def handle_event(_, state), do: {:ok, state}
end
