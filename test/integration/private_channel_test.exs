defmodule Poxa.Integration.PrivateChannelTest do
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

  test "subscribe a private channel", context do
    pid = context[:pid]
    channel = "private-channel"

    Pusher.WS.subscribe!(pid, channel)

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: %{}},
                   1_000
  end

  test "subscribe to a private channel and trigger event ", context do
    pid = context[:pid]
    channel = "private-channel"

    Pusher.WS.subscribe!(pid, channel)

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: %{}},
                   1_000

    Pusher.trigger(context.client, "test_event", %{data: 42}, channel)

    assert_receive %{channel: ^channel, event: "test_event", data: %{"data" => 42}},
                   1_000
  end

  test "client event on populated private channel", context do
    pid = context[:pid]
    channel = "private-channel"

    {:ok, other_pid, _} = Connection.connect()
    Pusher.WS.subscribe!(other_pid, channel)

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: _},
                   1_000

    Pusher.WS.subscribe!(pid, channel)

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: _},
                   1_000

    Pusher.WS.trigger_event!(pid, "client-event", %{}, channel)

    assert_receive %{channel: ^channel, event: "client-event", data: _},
                   1_000

    Pusher.WS.disconnect!(other_pid)
  end
end
