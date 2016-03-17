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

defmodule SpawnHelper do
  def spawn_registered_process(channel, value \\ :undefined) do
    parent = self
    spawn_link fn ->
      register_to_channel(channel, value)
      send parent, :registered
      receive do
        _ -> :wait
      end
    end
    receive do
      :registered -> :ok
    end
  end

  def register_to_channel(channel, value \\ :undefined) do
    Poxa.registry.register!(channel, value)
  end
end
