defmodule Poxa.ConsoleWSHandler do
  @behaviour :cowboy_websocket_handler

  def init(_transport, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  def websocket_init(_transport_name, req, _opts) do
    :gproc.reg({:p, :l, :console})
    {:ok, req, nil}
  end

  def websocket_handle(_data, req, state), do: {:ok, req, state}

  def websocket_info({_pid, msg}, req, state) do
    {:reply, {:text, msg}, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    :gproc.goodbye
    :ok
  end
end
