defmodule Poxa.PingHandler do
  @moduledoc """
  Simple ping endpoint that returns 200 "Pong!" for any request
  """
  require Logger

  @doc false
  def init(_transport, req, _Opts), do: {:ok, req, nil}

  @doc false
  def handle(req, state) do
    {:ok, req} = :cowboy_req.reply(200, [], "Pong!", req)
    Logger.info("Ping requested")
    {:ok, req, state}
  end

  @doc false
  def terminate(_, _, _), do: :ok
end
