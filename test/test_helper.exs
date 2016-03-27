ExUnit.start
ExUnit.configure(exclude: :pending)

defmodule Connection do
  def connect do
    {:ok, pid} = PusherClient.start_link("ws://localhost:8080", "app_key", "secret", stream_to: self)

    socket_id = receive do
      %{channel: nil, event: "pusher:connection_established", data: %{"socket_id" => socket_id}} -> socket_id
    end
    {:ok, pid, socket_id}
  end
end
