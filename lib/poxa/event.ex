defmodule Poxa.Event do
  @moduledoc """
  GenEvent interface to internal events
  """

  @doc """
  Uses GenEvent to notify a new event.

  It adds the socket_id if not available
  """
  @spec notify(atom, map) :: :ok
  def notify(event, %{socket_id: _socket_id} = data) do
    GenEvent.notify(Poxa.Event, Map.put(data, :event, event))
  end
  def notify(event, data) do
    socket_id = Poxa.SocketId.mine
    notify(event, Map.put(data, :socket_id, socket_id))
  end

  def add_handler(handler, pid) do
    GenEvent.add_mon_handler(Poxa.Event, handler, pid)
  end

  def remove_handler(handler, pid) do
    GenEvent.remove_handler(Poxa.Event, handler, pid)
  end
end
