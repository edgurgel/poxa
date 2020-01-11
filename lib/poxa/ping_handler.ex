defmodule Poxa.PingHandler do
  @moduledoc """
  Simple ping endpoint that returns 200 "Pong!" for any request
  """
  require Logger

  @doc false
  def init(req, _Opts) do
    req = :cowboy_req.reply(200, %{"content-type" => "text/plain"}, "Pong!", req)
    Logger.debug("Ping requested")
    {:ok, req, nil}
  end

  @doc false
  def terminate(_, _, _), do: :ok
end
