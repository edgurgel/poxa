defmodule Poxa.PusherEventTest do
  use ExUnit.Case
  import :meck
  import Poxa.PusherEvent
  alias Poxa.PusherEvent

  setup do
    on_exit fn -> unload end
    :ok
  end

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
    assert build("app_id", event) == {:ok, %PusherEvent{app_id: "app_id", name: "event_etc", data: "event_data", channels: ["channel_name"]}}
  end

  test "build PusherEvent with multiple channels" do
    event = %{"channels" => ["channel_name1", "channel_name2"],
              "data" => "event_data",
              "name" => "event_etc"}
    assert build("app_id", event) ==
      {:ok, %PusherEvent{app_id: "app_id", name: "event_etc", data: "event_data", channels: ["channel_name1","channel_name2"]}}
  end

  test "build PusherEvent with excluding socket_id" do
    event = %{"channel" => "channel_name",
              "data" => "event_data",
              "socket_id" => "123.456",
              "name" => "event_etc"}
    assert build("app_id", event) == {:ok, %PusherEvent{app_id: "app_id", name: "event_etc", data: "event_data", channels: ["channel_name"], socket_id: "123.456"}}
  end

  test "build PusherEvent with no app_id" do
    event = %{"channel" => "channel_name",
              "data" => "event_data",
              "name" => "event_etc"}
    assert build(nil, event) == {:error, :invalid_event}
  end

  test "build PusherEvent with invalid socket_id" do
    event = %{"channel" => "channel_name",
              "data" => "event_data",
              "socket_id" => "123:456",
              "name" => "event_etc"}
    assert build("app_id", event) == {:error, :invalid_event}
  end

  test "build PusherEvent with invalid channel name" do
    event = %{"channel" => "channel:name",
              "data" => "event_data",
              "socket_id" => "123.456",
              "name" => "event_etc"}
    assert build("app_id", event) == {:error, :invalid_event}
  end

  test "build_client_event with excluding socket_id" do
    event = %{"channel" => "channel_name",
              "data" => "event_data",
              "name" => "event_etc"}
    assert build_client_event("app_id", event, "123.456") ==
      {:ok, %PusherEvent{app_id: "app_id", name: "event_etc", data: "event_data", channels: ["channel_name"], socket_id: "123.456"}}
  end

  test "build_client_event with invalid excluding socket_id" do
    event = %{"channel" => "channel_name",
              "data" => "event_data",
              "name" => "event_etc"}
    assert build_client_event("app_id", event, "123:456") == {:error, :invalid_event}
  end

  test "build_client_event with invalid channel name" do
    event = %{"channel" => "channel:name",
              "data" => "event_data",
              "name" => "event_etc"}
    assert build_client_event("app_id", event, "123.456") == {:error, :invalid_event}
  end

  test "sending message to a channel" do
    expect(:gproc, :send, [{[{:p, :l, {:pusher, "app_id", "channel123"}}, {self, :msg, nil}], :ok}])
    expected = %{channel: "channel123", data: "data", event: "event"}
    expect(JSX, :encode!, [{[expected], :msg}])
    event = %PusherEvent{app_id: "app_id", channels: ["channel123"], data: "data", name: "event"}

    assert publish(event) == :ok

    assert validate [:gproc, JSX]
  end

  test "sending message to channels excluding a socket id" do
    expected = %{channel: "channel123", data: %{}, event: "event"}
    expect(JSX, :encode!, [{[expected], :msg}])
    expect(:gproc, :send, [{[{:p, :l, {:pusher, "app_id", "channel123"}}, {self, :msg, "SocketId"}], :ok}])

    assert publish(%PusherEvent{app_id: "app_id", data: %{}, channels: ["channel123"], name: "event", socket_id: "SocketId"}) == :ok

    assert validate [:gproc, JSX]
  end
end
