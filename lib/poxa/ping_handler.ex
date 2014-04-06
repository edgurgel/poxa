defmodule Poxa.PingHandler do
  require Lager
  def init(_transport, req, _Opts), do: {:ok, req, nil}

  def handle(req, state) do
    {:ok, req} = :cowboy_req.reply(200, [], "Pong!", req)
    Lager.info "Ping requested"
    {:ok, req, state}
  end

  def terminate(_, _, _), do: :ok

end
