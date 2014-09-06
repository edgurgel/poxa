defmodule Poxa.Integration.PresenceChannelTest do
  use ExUnit.Case

  @moduletag :integration

  setup do
    {:ok, pid} = PusherClient.start_link("ws://localhost:8080", "app_key", "secret", stream_to: self)
    Application.ensure_all_started(:pusher)
    Pusher.configure!("localhost", 8080, "app_id", "app_key", "secret")
    on_exit fn ->
      PusherClient.disconnect! pid
    end
    {:ok, [pid: pid]}
  end

  test "subscribe a presence channel", context do
    pid = context[:pid]
    channel = "presence-channel"

    assert_receive %{channel: nil,
                     event: "pusher:connection_established",
                     data: _}, 1_000

    PusherClient.subscribe!(pid, channel,
                            %PusherClient.User{id: 123, info: %{k: "v"}})

    data = %{"presence" =>
              %{"count" => 1,
                "hash" => %{"123" => %{"k" => "v"}},
                "ids" => ["123"]}
            }
    assert_receive %{channel: ^channel,
                     event: "pusher:subscription_succeeded",
                     data: ^data}, 1_000
  end

  test "subscribe to a presence channel and trigger event ", context do
    pid = context[:pid]
    channel = "presence-channel"

    assert_receive %{channel: nil,
                     event: "pusher:connection_established",
                     data: _}, 1_000

    PusherClient.subscribe!(pid, channel, %PusherClient.User{id: 123})
    Pusher.trigger("test_event", %{data: 42}, channel)

    assert_receive %{channel: ^channel,
                     event: "test_event",
                     data: %{"data" => 42}}, 1_000
  end
end
