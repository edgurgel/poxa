defmodule Poxa.Integration.PrivateChannelTest do
  use ExUnit.Case

  @moduletag :integration

  setup_all do
    Application.ensure_all_started(:pusher)
    Pusher.configure!("localhost", 8080, "app_id", "app_key", "secret")
    :ok
  end

  setup do
    {:ok, pid, socket_id} = Connection.connect

    on_exit fn -> PusherClient.disconnect! pid end

    {:ok, [pid: pid, socket_id: socket_id]}
  end

  test "subscribe a private channel", context do
    pid = context[:pid]
    channel = "private-channel"

    PusherClient.subscribe!(pid, channel)

    assert_receive %{channel: ^channel,
                     event: "pusher:subscription_succeeded",
                     data: %{}}, 1_000
  end

  test "subscribe to a private channel and trigger event ", context do
    pid = context[:pid]
    channel = "private-channel"

    PusherClient.subscribe!(pid, channel)

    assert_receive %{channel: ^channel,
                     event: "pusher:subscription_succeeded",
                     data: %{}}, 1_000

    Pusher.trigger("test_event", %{data: 42}, channel)

    assert_receive %{channel: ^channel,
                     event: "test_event",
                     data: %{"data" => 42}}, 1_000
  end

  test "client event on populated private channel", context do
    pid = context[:pid]
    channel = "private-channel"

    {:ok, other_pid, _} = Connection.connect
    PusherClient.subscribe!(other_pid, channel)

    assert_receive %{channel: ^channel,
                     event: "pusher:subscription_succeeded",
                     data: _}, 1_000

    PusherClient.subscribe!(pid, channel)

    assert_receive %{channel: ^channel,
                     event: "pusher:subscription_succeeded",
                     data: _}, 1_000

    PusherClient.trigger_event!(pid, "client-event", %{}, channel)

    assert_receive %{channel: ^channel,
                     event: "client-event",
                     data: _}, 1_000
    PusherClient.disconnect!(other_pid)
  end
end
