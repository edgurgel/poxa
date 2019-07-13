defmodule Poxa.Integration.PresenceChannelTest do
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

  test "subscribe a presence channel", context do
    pid = context[:pid]
    channel = "presence-channel"

    Pusher.WS.subscribe!(pid, channel, %Pusher.WS.User{id: 123, info: %{k: "v"}})

    data = %{"presence" => %{"count" => 1, "hash" => %{"123" => %{"k" => "v"}}, "ids" => ["123"]}}

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: ^data},
                   1_000
  end

  test "subscribe to a presence channel and trigger event ", context do
    pid = context[:pid]
    channel = "presence-channel"

    Pusher.WS.subscribe!(pid, channel, %Pusher.WS.User{id: 123})

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: _},
                   1_000

    Pusher.trigger(context.client, "test_event", %{data: 42}, channel)

    assert_receive %{channel: ^channel, event: "test_event", data: %{"data" => 42}},
                   1_000

    assert Pusher.users(context.client, channel) == {:ok, [%{"id" => "123"}]}
  end

  test "member_added event on populated presence channel", context do
    pid = context[:pid]
    channel = "presence-channel"

    {:ok, other_pid, _} = Connection.connect()
    Pusher.WS.subscribe!(other_pid, channel, %Pusher.WS.User{id: 456, info: %{k1: "v1"}})

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: _},
                   1_000

    Pusher.WS.subscribe!(pid, channel, %Pusher.WS.User{id: 123, info: %{k2: "v2"}})

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: _},
                   1_000

    assert_receive %{
                     channel: "presence-channel",
                     data: %{"user_id" => "123", "user_info" => %{"k2" => "v2"}},
                     event: "pusher_internal:member_added"
                   },
                   1_000

    assert Pusher.users(context.client, channel) == {:ok, [%{"id" => "123"}, %{"id" => "456"}]}

    Pusher.WS.disconnect!(other_pid)
  end

  test "client event on populated presence channel", context do
    pid = context[:pid]
    channel = "presence-channel"

    {:ok, other_pid, _} = Connection.connect()
    Pusher.WS.subscribe!(other_pid, channel, %Pusher.WS.User{id: 456, info: %{k1: "v1"}})

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: _},
                   1_000

    Pusher.WS.subscribe!(pid, channel, %Pusher.WS.User{id: 123, info: %{k2: "v2"}})

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: _},
                   1_000

    Pusher.WS.trigger_event!(pid, "client-event", %{}, channel)

    assert_receive %{channel: ^channel, event: "client-event", data: _},
                   1_000

    Pusher.WS.disconnect!(other_pid)
  end

  test "member_removed event on populated presence channel", context do
    pid = context[:pid]
    channel = "presence-channel"
    Pusher.WS.subscribe!(pid, channel, %Pusher.WS.User{id: 123, info: %{k2: "v2"}})

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: _},
                   1_000

    {:ok, other_pid, _} = Connection.connect()
    Pusher.WS.subscribe!(other_pid, channel, %Pusher.WS.User{id: 456, info: %{k1: "v1"}})
    Pusher.WS.unsubscribe!(other_pid, channel)

    assert_receive %{
                     channel: "presence-channel",
                     data: %{"user_id" => "456"},
                     event: "pusher_internal:member_removed"
                   },
                   1_000

    assert Pusher.users(context.client, channel) == {:ok, [%{"id" => "123"}]}

    Pusher.WS.disconnect!(other_pid)
  end

  test "member_removed event on populated presence channel with same user id", context do
    pid = context[:pid]
    channel = "presence-channel"
    Pusher.WS.subscribe!(pid, channel, %Pusher.WS.User{id: 123, info: %{k2: "v2"}})

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: _},
                   1_000

    {:ok, other_pid, _} = Connection.connect()
    Pusher.WS.subscribe!(other_pid, channel, %Pusher.WS.User{id: 123, info: %{k1: "v1"}})

    assert_receive %{channel: ^channel, event: "pusher:subscription_succeeded", data: _},
                   1_000

    Pusher.WS.unsubscribe!(other_pid, channel)

    refute_receive %{
                     channel: "presence-channel",
                     data: %{"user_id" => "123"},
                     event: "pusher_internal:member_removed"
                   },
                   1_000

    assert Pusher.users(context.client, channel) == {:ok, [%{"id" => "123"}]}

    Pusher.WS.disconnect!(other_pid)
  end
end
