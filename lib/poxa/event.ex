defmodule Poxa.Event do
  def notify(event, app_id, data) do
    poxa_event = data |> Map.put(:event, event) |> Map.put(:app_id, app_id)
    :gen_event.sync_notify(Poxa.Event, poxa_event)
  end

  def add_handler(handler, pid) do
    GenEvent.add_mon_handler(Poxa.Event, handler, pid)
  end

  def remove_handler(handler, pid) do
    GenEvent.remove_handler(Poxa.Event, handler, pid)
  end
end
