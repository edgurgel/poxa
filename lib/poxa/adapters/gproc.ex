defmodule Poxa.Adapter.GProc do
  @behavour Poxa.Registry
  @moduledoc """
  """

  import :gproc

  def register(channel) do
    reg({:p, :l, {:pusher, channel}})
  end

  def unregister(channel) do
    unreg({:p, :l, {:pusher, channel}});
  end
end
