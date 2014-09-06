defmodule Poxa.Integration.PublicChannelTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  setup do
    {:ok, pid} = Connection.connect
    Application.ensure_all_started(:pusher)
    Pusher.configure!("localhost", 8080, "app_id", "app_key", "secret")
    on_exit fn ->
      PusherClient.disconnect! pid
    end
    {:ok, [pid: pid]}
  end

  test "subscribe to a public channel", context do
    pid = context[:pid]
    channel = "channel"

    PusherClient.subscribe!(pid, channel)

    assert_receive %{channel: ^channel,
                     event: "pusher:subscription_succeeded",
                     data: %{}}, 1_000
  end

  test "subscribe to a public channel and trigger event", context do
    pid = context[:pid]
    channel = "channel"

    PusherClient.subscribe!(pid, channel)
    Pusher.trigger("test_event", %{data: 42}, channel)

    assert_receive %{channel: ^channel,
                     event: "test_event",
                     data: %{"data" => 42}}, 1_000
  end
end
