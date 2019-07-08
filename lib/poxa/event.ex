defmodule Poxa.Event do
  @moduledoc """
  Uses gproc to publish and subscribe internal events
  """

  @gproc_key {:p, :l, :internal_event}

  @doc false
  def notify(event, %{socket_id: _socket_id} = data) do
    :gproc.send(@gproc_key, {:internal_event, Map.put(data, :event, event)})
  end

  def notify(event, data) do
    socket_id = Poxa.SocketId.mine()
    notify(event, Map.put(data, :socket_id, socket_id))
  end

  @doc false
  def subscribe do
    :gproc.reg(@gproc_key)
  end
end
