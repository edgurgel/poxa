defmodule Poxa.WebHook.EventTable do
  @moduledoc """
  This module provides functions to initialize and manipulate a table of events
  to be sent to the web hook.
  """
  @table_name :web_hook_events

  import :ets, only: [new: 2, select: 2, select_delete: 2]

  @doc """
  This function initializes the ETS table where the events will be stored.
  """
  def init do
    new(@table_name, [:bag, :public, :named_table])
  end

  @doc """
  This function inserts events in the ETS table. It receives a `delay` in
  milliseconds corresponding to how much time each event must be delayed before
  being sent. This `delay` is summed up with the current timestamp and used
  as key of the ETS table.

  It doesn't always insert a new value, though. In the case where there is a
  corresponding event(e.g. `member_added` is being inserted when `member_removed`
  of the same user and channel is already in the the table), it does not insert the
  new event but it removes the old one. This is done to achieve delaying events as
  it is described in [pusher's documentation](https://pusher.com/docs/webhooks#delay)
  """
  def insert(_, delay \\ 0)
  def insert(event, delay) when not is_list(event), do: insert([event], delay)

  def insert(events, delay) do
    Enum.filter(events, fn event ->
      if delete_corresponding(event) == 0 do
        :ets.insert(@table_name, {time_ms() + delay, event})
      end
    end)
  end

  @doc """
  This function returns all events present in the ETS table.
  """
  def all, do: filter_events([])

  @doc """
  This function returns all events in the ETS table that are ready to be sent
  for a given `timestamp`.
  """
  def ready(timestamp \\ time_ms() + 1), do: {timestamp, filter_events([{:<, :"$1", timestamp}])}

  defp filter_events(filter) do
    select(@table_name, [{{:"$1", :"$2"}, filter, [:"$2"]}])
  end

  @doc """
  This function removes all events in the ETS table that are ready to be sent
  before a certain timestamp.
  """
  def clear_older(timestamp),
    do: select_delete(@table_name, [{{:"$1", :"$2"}, [], [{:<, :"$1", timestamp}]}])

  defp delete_corresponding(%{name: "channel_occupied", channel: channel}) do
    match = [
      {{:_, %{channel: :"$1", name: "channel_vacated"}}, [], [{:==, {:const, channel}, :"$1"}]}
    ]

    select_delete(@table_name, match)
  end

  defp delete_corresponding(%{name: "member_added", channel: channel, user_id: user_id}) do
    match = [
      {{:_, %{channel: :"$1", name: "member_removed", user_id: :"$2"}}, [],
       [{:andalso, {:==, {:const, user_id}, :"$2"}, {:==, {:const, channel}, :"$1"}}]}
    ]

    select_delete(@table_name, match)
  end

  defp delete_corresponding(_), do: 0

  defp time_ms, do: :erlang.system_time(:milli_seconds)
end
