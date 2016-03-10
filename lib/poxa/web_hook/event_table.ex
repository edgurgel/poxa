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
  """
  def insert(_, delay \\ 0)
  def insert(event, delay) when not is_list(event), do: insert([event], delay)
  def insert(events, delay) do
    Enum.each events, fn(event) ->
      true = :ets.insert(@table_name, {time_ms + delay, event})
    end
    true
  end

  @doc """
  This function returns all events present in the ETS table.
  """
  def all, do: filter_events []

  @doc """
  This function returns all events in the ETS table that are ready to be sent
  for a given `timestamp`.
  """
  def ready(timestamp \\ time_ms + 1), do: {timestamp, filter_events [{:<, :"$1", timestamp}]}

  defp filter_events(filter) do
    select(@table_name, [{{:"$1", :"$2"}, filter, [:"$2"]}])
  end

  @doc """
  This function removes all events in the ETS table that are ready to be sent
  before a certain timestamp.
  """
  def clear_older(timestamp), do: select_delete(@table_name, [{{:"$1", :"$2"}, [], [{:<, :"$1", timestamp}]}])

  defp time_ms, do: :erlang.system_time(:milli_seconds)
end
