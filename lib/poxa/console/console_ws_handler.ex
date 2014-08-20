defmodule Poxa.Console.WSHandler do
  @behaviour :cowboy_websocket_handler
  require Logger
  alias Poxa.Authentication

  def init(_transport, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  def websocket_init(_transport_name, req, _opts) do
    {method, req} = :cowboy_req.method(req)
    {path, req} = :cowboy_req.path(req)
    {qs_vals, req} = :cowboy_req.qs_vals(req)

    if Authentication.check(method, path, "", qs_vals) == :ok do
      :gproc.reg({:p, :l, :console})
      {:ok, req, nil}
    else
      Logger.error "Failed to authenticate on Console Websocket"
      {:shutdown, req}
    end
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
