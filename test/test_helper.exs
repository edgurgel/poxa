ExUnit.start

defmodule Connection do
  def connect do
    {:ok, pid} = PusherClient.start_link("ws://localhost:8080", "app_key", "secret", stream_to: self)

    receive do
      %{channel: nil, event: "pusher:connection_established", data: _} -> :ok
    end
    {:ok, pid}
  end
end
