defmodule Poxa.PusherEventTest do
  use ExUnit.Case, async: true
  import Mimic
  import Poxa.PusherEvent
  alias Poxa.PusherEvent

  setup :verify_on_exit!

  doctest Poxa.PusherEvent

  test "connection established output" do
    json = "{\"event\":\"pusher:connection_established\",\"data\":\"{\\\"socket_id\\\":\\\"SocketId\\\",\\\"activity_timeout\\\":120}\"}"
    assert connection_established("SocketId") == json
  end

  test "subscription established output" do
    json = "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":{},\"channel\":\"channel\"}"
    assert subscription_succeeded("channel") == json
  end

  test "subscription error output" do
    json = "{\"event\":\"pusher:subscription_error\",\"data\":{}}"
    assert subscription_error() == json
  end

  test "pusher error output" do
    json = "{\"event\":\"pusher:error\",\"data\":{\"message\":\"An error\",\"code\":null}}"
    assert pusher_error("An error") == json
  end

  test "pusher error with code output" do
    json = "{\"event\":\"pusher:error\",\"data\":{\"message\":\"An error\",\"code\":123}}"
    assert pusher_error("An error", 123) == json
  end

  test "pong output" do
    json = "{\"event\":\"pusher:pong\",\"data\":{}}"
    assert pong() == json
  end

  test "presence member added output" do
    json = "{\"event\":\"pusher_internal:member_added\",\"data\":\"{\\\"user_info\\\":\\\"userinfo\\\",\\\"user_id\\\":\\\"userid\\\"}\",\"channel\":\"channel\"}"
    assert presence_member_added("channel", "userid", "userinfo") == json
  end

  test "presence member removed output" do
    json = "{\"event\":\"pusher_internal:member_removed\",\"data\":\"{\\\"user_id\\\":\\\"userid\\\"}\",\"channel\":\"channel\"}"
    assert presence_member_removed("channel", "userid") == json
  end

  test "presence subscription succeeded" do
    json = "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"ids\\\":[\\\"userid\\\"],\\\"hash\\\":{\\\"userid\\\":{\\\"user\\\":\\\"info\\\"}},\\\"count\\\":1}}\",\"channel\":\"presence-channel\"}"
    subscription = %Poxa.PresenceSubscription{channel: "presence-channel",
                                              channel_data: %{"userid" => %{ "user" => "info"}}}
    assert subscription_succeeded(subscription) == json
  end

  test "build PusherEvent with 1 channel" do
    event = %{"channel" => "channel_name",
              "data" => "event_data",
              "name" => "event_etc"}
    assert build(event) == {:ok, %PusherEvent{name: "event_etc", data: "event_data", channels: ["channel_name"]}}
  end

  test "build PusherEvent with multiple channels" do
    event = %{"channels" => ["channel_name1", "channel_name2"],
              "data" => "event_data",
              "name" => "event_etc"}
    assert build(event) == {:ok, %PusherEvent{name: "event_etc", data: "event_data", channels: ["channel_name1","channel_name2"]}}
  end

  test "build PusherEvent with excluding socket_id" do
    event = %{"channel" => "channel_name",
              "data" => "event_data",
              "socket_id" => "123.456",
              "name" => "event_etc"}
    assert build(event) == {:ok, %PusherEvent{name: "event_etc", data: "event_data", channels: ["channel_name"], socket_id: "123.456"}}
  end

  test "build PusherEvent with invalid socket_id" do
    event = %{"channel" => "channel_name",
              "data" => "event_data",
              "socket_id" => "123:456",
              "name" => "event_etc"}
    assert build(event) == {:error, :invalid_event}
  end

  test "build PusherEvent with invalid channel name" do
    event = %{"channel" => "channel:name",
              "data" => "event_data",
              "socket_id" => "123.456",
              "name" => "event_etc"}
    assert build(event) == {:error, :invalid_event}
  end

  test "build_client_event with excluding socket_id" do
    event = %{"channel" => "channel_name",
              "data" => "event_data",
              "name" => "event_etc"}
    stub(Poxa.PresenceChannel, :my_user_id, fn _ -> "user-789" end)
    assert build_client_event(event, "123.456") == {:ok, %PusherEvent{name: "event_etc", data: "event_data", channels: ["channel_name"], socket_id: "123.456", user_id: "user-789"}}
  end

  test "build_client_event with invalid excluding socket_id" do
    event = %{"channel" => "channel_name",
              "data" => "event_data",
              "name" => "event_etc"}
    stub(Poxa.PresenceChannel, :my_user_id, fn _ -> "user-789" end)
    assert build_client_event(event, "123:456") == {:error, :invalid_event}
  end

  test "build_client_event with invalid channel name" do
    event = %{"channel" => "channel:name",
              "data" => "event_data",
              "name" => "event_etc"}

    stub(Poxa.PresenceChannel, :my_user_id, fn _ -> "user-789" end)
    assert build_client_event(event, "123.456") == {:error, :invalid_event}
  end

  test "sending message to a channel" do
    pid = self()
    expect(Poxa.registry, :send!, fn :msg, "channel123", ^pid, nil -> :ok end)
    expected = %{channel: "channel123", data: "data", event: "event"}
    expect(Poison, :encode!, fn ^expected -> :msg end)
    event = %PusherEvent{channels: ["channel123"], data: "data", name: "event"}

    assert publish(event) == :ok
  end

  test "sending message to channels excluding a socket id" do
    pid = self()
    expected = %{channel: "channel123", data: %{}, event: "event"}
    expect(Poison, :encode!, fn ^expected -> :msg end)
    expect(Poxa.registry, :send!, fn :msg, "channel123", ^pid, "SocketId" -> :ok end)

    assert publish(%PusherEvent{data: %{}, channels: ["channel123"], name: "event", socket_id: "SocketId"}) == :ok
  end
end
