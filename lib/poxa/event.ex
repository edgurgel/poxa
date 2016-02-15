defmodule Poxa.Event do
  @moduledoc """
  A worker wrapper around Poxa.Event specific GenEvent functions, namely adding
  and removing handlers, and triggering sync_notify calls.
  """

  def notify(event, data), do: :gen_event.sync_notify(Poxa.Event, Map.put(data, :event, event))

  def add_handler(handler, pid) do
    GenEvent.add_mon_handler(Poxa.Event, handler, pid)
  end

  def remove_handler(handler, pid) do
    GenEvent.remove_handler(Poxa.Event, handler, pid)
  end
end
