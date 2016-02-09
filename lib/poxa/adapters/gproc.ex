defmodule Poxa.Adapter.GProc do
  @behavour Poxa.Registry
  @moduledoc """
  """

  import :gproc

  def register(channel) do
    reg({:p, :l, {:pusher, channel}})
  end

  def register(channel, {user_id, user_info}) do
    :gproc.reg({:p, :l, {:pusher, channel}}, {user_id, user_info})
  end

  def unregister(channel) do
    unreg({:p, :l, {:pusher, channel}});
  end
end
