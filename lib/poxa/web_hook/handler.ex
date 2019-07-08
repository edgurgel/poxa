defmodule Poxa.WebHook.Handler do
  @moduledoc """
  This module is a event handler that deals with events as they happen
  and then adds them to the web hook event table.
  """

  use GenServer
  alias Poxa.WebHook.EventData
  alias Poxa.WebHook.EventTable

  @delay 1500

  @doc false
  def start_link(), do: GenServer.start_link(__MODULE__, [])

  @doc false
  def init(_) do
    Poxa.Event.subscribe()
    {:ok, nil}
  end

  def handle_info({:internal_event, event}, state) do
    handle_event(event)
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp handle_event(%{event: :channel_vacated, channel: channel}) do
    EventData.channel_vacated(channel) |> EventTable.insert(@delay)
  end

  defp handle_event(%{event: :channel_occupied, channel: channel}) do
    EventData.channel_occupied(channel) |> EventTable.insert()
  end

  defp handle_event(%{event: :member_added, channel: channel, user_id: user_id}) do
    EventData.member_added(channel, user_id) |> EventTable.insert()
  end

  defp handle_event(%{event: :member_removed, channel: channel, user_id: user_id}) do
    EventData.member_removed(channel, user_id) |> EventTable.insert(@delay)
  end

  defp handle_event(
         %{
           event: :client_event_message,
           socket_id: socket_id,
           channels: channels,
           name: name,
           data: data
         } = event
       ) do
    for c <- channels do
      EventData.client_event(c, name, data, socket_id, event[:user_id])
    end
    |> EventTable.insert()
  end

  # Events that cannot trigger any webhook event
  defp handle_event(_), do: :ok
end
