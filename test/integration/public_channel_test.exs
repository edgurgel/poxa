defmodule Poxa.Integration.PublicChannelTest do
  use ExUnit.Case

  @moduletag :integration

  setup_all do
    Application.ensure_all_started(:pusher)

    client = %Pusher.Client{
      endpoint: "localhost:8080",
      app_id: "app_id",
      app_key: "app_key",
      secret: "secret"
    }

    {:ok, client: client}
  end

  setup do
    {:ok, pid, socket_id} = Connection.connect()

    on_exit(fn -> Pusher.WS.disconnect!(pid) end)

    {:ok, [pid: pid, socket_id: socket_id]}
  end

  test "subscribe to a public channel", context do
    pid = context[:pid]
    channel = "channel"

    Pusher.WS.subscribe!(pid, channel)

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: %{}},
                   1_000
  end

  test "subscribe to a public channel and trigger event", context do
    pid = context[:pid]
    channel = "channel"

    Pusher.WS.subscribe!(pid, channel)

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: %{}},
                   1_000

    Pusher.trigger(context.client, "test_event", %{data: 42}, channel)

    assert_receive %{channel: ^channel, event: "test_event", data: %{"data" => 42}},
                   1_000
  end

  test "subscribe to a public channel and trigger event excluding itself()", context do
    pid = context[:pid]
    channel = "channel"

    Pusher.WS.subscribe!(pid, channel)

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: %{}},
                   1_000

    Pusher.trigger(context.client, "test_event", %{data: 42}, channel, context[:socket_id])

    refute_receive %{channel: ^channel, event: "test_event", data: %{"data" => 42}}, 1_000
  end
end
