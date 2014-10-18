defmodule Poxa.Event do
  def notify(event, data), do: :gen_event.sync_notify(Poxa.Event, Map.put(data, :event, event))

  def add_handler(pid, handler) do
    GenEvent.add_mon_handler(Poxa.Event, handler, pid)
  end
end
