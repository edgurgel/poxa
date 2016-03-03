defmodule Poxa.Event do
  def notify(event, data), do: GenEvent.ack_notify(Poxa.Event, Map.put(data, :event, event))

  def add_handler(handler, pid) do
    GenEvent.add_mon_handler(Poxa.Event, handler, pid)
  end

  def remove_handler(handler, pid) do
    GenEvent.remove_handler(Poxa.Event, handler, pid)
  end
end
