defmodule Poxa.PingHandler do
  @moduledoc """
  Simple ping endpoint that returns 200 "Pong!" for any request
  """
  require Logger

  @doc false
  def init(_transport, req, _Opts), do: {:ok, req, nil}

  @doc false
  def handle(req, state) do
    req = :cowboy_req.reply(200, %{"content-type" => "text/plain"}, "Hello World!", req)
    Logger.debug("Ping requested")
    {:ok, req, state}
  end

  @doc false
  def terminate(_, _, _), do: :ok
end
