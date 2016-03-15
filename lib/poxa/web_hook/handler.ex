defmodule Poxa.WebHook.Handler do
  @moduledoc """
  This module is a event handler that deals with events as they happen 
  and then adds them to the web hook event table.
  """

  use GenEvent
  alias Poxa.WebHook.EventData
  alias Poxa.WebHook.EventTable

  @delay 1500

  @doc false
  def init(_), do: {:ok, nil}

  @doc false
  def handle_event(%{event: :channel_vacated, channel: channel}, state) do
    EventData.channel_vacated(channel) |> EventTable.insert(@delay)
    {:ok, state}
  end

  def handle_event(%{event: :channel_occupied, channel: channel}, state) do
    EventData.channel_occupied(channel) |> EventTable.insert
    {:ok, state}
  end

  def handle_event(%{event: :member_added, channel: channel, user_id: user_id}, state) do
    EventData.member_added(channel, user_id) |> EventTable.insert
    {:ok, state}
  end

  def handle_event(%{event: :member_removed, channel: channel, user_id: user_id}, state) do
    EventData.member_removed(channel, user_id) |> EventTable.insert(@delay)
    {:ok, state}
  end

  def handle_event(%{event: :client_event_message, socket_id: socket_id, channels: channels, name: name, data: data}, state) do
    for c <- channels do
      EventData.client_event(c, name, data, socket_id, nil)
    end |> EventTable.insert
    {:ok, state}
  end

  # Events that cannot trigger any webhook event
  def handle_event(_, state), do: {:ok, state}
end
