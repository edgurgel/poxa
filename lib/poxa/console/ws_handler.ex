defmodule Poxa.Console.WSHandler do
  @behaviour :cowboy_websocket_handler
  @moduledoc """
  A separate websocket handler for the admin console.
  All messages which are processed by Poxa will be relayed to the admin
  console for viewing and monitoring.
  """

  require Logger
  alias Poxa.Authentication

  @doc false
  def init(_transport, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  @doc false
  def websocket_init(_transport_name, req, _opts) do
    {method, req} = :cowboy_req.method(req)
    {path, req} = :cowboy_req.path(req)
    {qs_vals, req} = :cowboy_req.qs_vals(req)

    if Authentication.check(method, path, "", qs_vals) do
      :ok = Poxa.Event.add_handler({Poxa.Console, self}, self)
      {:ok, req, nil}
    else
      Logger.error "Failed to authenticate on Console Websocket"
      {:shutdown, req}
    end
  end

  @doc false
  def websocket_handle(_data, req, state), do: {:ok, req, state}

  @doc false
  def websocket_info(msg, req, state) do
    {:reply, {:text, msg}, req, state}
  end

  @doc false
  def websocket_terminate(_reason, _req, _state) do
    Poxa.Event.remove_handler({Poxa.Console, self}, self)
    :ok
  end
end
