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
    :gproc.reg({:p, :l, {:pusher, channel}}, value)
  end
end
