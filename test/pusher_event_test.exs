defmodule Poxa.PusherEventTest do
  use ExUnit.Case
  import :meck
  import Poxa.PusherEvent
  alias Poxa.PusherEvent

  setup do
    new Poxa.registry
    on_exit fn -> unload end
    :ok
  end

  doctest Poxa.PusherEvent

  test "connection established output" do
    json ="{\"data\":\"{\\\"activity_timeout\\\":120,\\\"socket_id\\\":\\\"SocketId\\\"}\",\"event\":\"pusher:connection_established\"}"
    assert connection_established("SocketId") == json
  end

  test "subscription established output" do
    json = "{\"channel\":\"channel\",\"data\":{},\"event\":\"pusher_internal:subscription_succeeded\"}"
    assert subscription_succeeded("channel") == json
  end

  test "subscription error output" do
    json = "{\"data\":{},\"event\":\"pusher:subscription_error\"}"
    assert subscription_error == json
  end

  test "pusher error output" do
    json = "{\"data\":{\"code\":null,\"message\":\"An error\"},\"event\":\"pusher:error\"}"
    assert pusher_error("An error") == json
  end

  test "pusher error with code output" do
    json = "{\"data\":{\"code\":123,\"message\":\"An error\"},\"event\":\"pusher:error\"}"
    assert pusher_error("An error", 123) == json
  end

  test "pong output" do
    json ="{\"data\":{},\"event\":\"pusher:pong\"}"
    assert pong == json
  end

  test "presence member added output" do
    json ="{\"channel\":\"channel\",\"data\":\"{\\\"user_id\\\":\\\"userid\\\",\\\"user_info\\\":\\\"userinfo\\\"}\",\"event\":\"pusher_internal:member_added\"}"
    assert presence_member_added("channel", "userid", "userinfo") == json
  end

  test "presence member removed output" do
    json ="{\"channel\":\"channel\",\"data\":\"{\\\"user_id\\\":\\\"userid\\\"}\",\"event\":\"pusher_internal:member_removed\"}"
    assert presence_member_removed("channel", "userid") == json
  end

  test "presence subscription succeeded" do
    json = "{\"channel\":\"presence-channel\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"hash\\\":{\\\"userid\\\":\\\"userinfo\\\"},\\\"ids\\\":[\\\"userid\\\"]}}\",\"event\":\"pusher_internal:subscription_succeeded\"}"
    subscription = %Poxa.PresenceSubscription{channel: "presence-channel",
                                              channel_data: [{"userid", "userinfo"}]}
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
    assert build_client_event(event, "123.456") == {:ok, %PusherEvent{name: "event_etc", data: "event_data", channels: ["channel_name"], socket_id: "123.456"}}
  end

  test "build_client_event with invalid excluding socket_id" do
    event = %{"channel" => "channel_name",
              "data" => "event_data",
              "name" => "event_etc"}
    assert build_client_event(event, "123:456") == {:error, :invalid_event}
  end

  test "build_client_event with invalid channel name" do
    event = %{"channel" => "channel:name",
              "data" => "event_data",
              "name" => "event_etc"}
    assert build_client_event(event, "123.456") == {:error, :invalid_event}
  end

  test "sending message to a channel" do
    expect(Poxa.registry, :send!, [{[:msg, "channel123", self, nil], :ok}])
    expected = %{channel: "channel123", data: "data", event: "event"}
    expect(JSX, :encode!, [{[expected], :msg}])
    event = %PusherEvent{channels: ["channel123"], data: "data", name: "event"}

    assert publish(event) == :ok

    assert validate [Poxa.registry, JSX]
  end

  test "sending message to channels excluding a socket id" do
    expected = %{channel: "channel123", data: %{}, event: "event"}
    expect(JSX, :encode!, [{[expected], :msg}])
    expect(Poxa.registry, :send!, [{[:msg, "channel123", self, "SocketId"], :ok}])

    assert publish(%PusherEvent{data: %{}, channels: ["channel123"], name: "event", socket_id: "SocketId"}) == :ok

    assert validate [Poxa.registry, JSX]
  end
end
