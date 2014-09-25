defmodule Poxa.PusherEventTest do
  use ExUnit.Case
  import :meck
  import Poxa.PusherEvent

  setup do
    new :gproc
    on_exit fn -> unload end
    :ok
  end

  doctest Poxa.PusherEvent

  test "valid? for valid event" do
    assert valid?(%{"name" => "publish", "data" => "{ \"key\" : \"value\" }"})
  end

  test "valid? for event without \"name\"" do
    refute valid?(%{"names" => "publish", "data" => "{ \"key\" : \"value\" }"})
  end

  test "valid? for event without \"data\"" do
    refute valid?(%{"name" => "publish", "dat" => "{ \"key\" : \"value\" }"})
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
    assert presence_subscription_succeeded("presence-channel", [{:pid, {"userid", "userinfo"}}, {:pid2, {"userid", "userinfo"}}]) == json
  end

  test "parse channels having a single channel" do
    data = %{"channel" => "channel_name",
             "name" => "event_etc"}
    expected_data = %{"name" => "event_etc"}
    assert parse_channels(data) == {expected_data, ["channel_name"], nil}
  end

  test "parse channels having multiple channels" do
    data = %{"channels" => ["channel_name1", "channel_name2"],
             "name" => "event_etc"}
    expected_data = %{"name" => "event_etc"}
    assert parse_channels(data) == {expected_data, ["channel_name1", "channel_name2"], nil}
  end

  test "parse channels having no channels" do
    data = %{"name" => "event_etc"}
    assert parse_channels(data) == {data, nil, nil}
  end

  test "parse channels excluding socket id" do
    data = %{"channel" => "channel_name",
             "name" => "event_etc",
             "socket_id" => "SocketId"}
    expected_data = %{"name" => "event_etc", "socket_id" => "SocketId"}
    assert parse_channels(data) == {expected_data, ["channel_name"], "SocketId"}
  end

  test "sending message to a channel" do
    pid = self
    new JSEX
    expect(:gproc, :lookup_pids, 1, [pid])
    expected = %{"channel" => "channel123"}
    expect(JSEX, :encode!, [{[expected], :msg}])

    assert send_message_to_channel("channel123", %{}, []) == :ok
    assert_receive { ^pid, :msg }

    assert validate :gproc
    assert validate JSEX
    unload JSEX
  end

  test "sending message to a channel excluding a pid" do
    new JSEX
    expect(:gproc, :lookup_pids, 1, [self])
    expected = %{"channel" => "channel123"}
    expect(JSEX, :encode!, [{[expected], :msg}])

    assert send_message_to_channel("channel123", %{}, [self]) == :ok

    assert validate :gproc
    assert validate JSEX
    unload JSEX
  end

  test "sending message to channels" do
    pid = self
    new JSEX
    expect(:gproc, :lookup_pids, 1, [pid])
    expected = %{"channel" => "channel123"}
    expect(JSEX, :encode!, [{[expected], :msg}])

    assert send_message_to_channels(["channel123"], %{}, nil) == :ok
    assert_receive { ^pid, :msg }

    assert validate :gproc
    assert validate JSEX
    unload JSEX
  end

  test "sending message to channels excluding a socket id" do
    new JSEX
    expect(:gproc, :lookup_pids, 1, [self])
    expected = %{"channel" => "channel123"}
    expect(JSEX, :encode!, [{[expected], :msg}])

    assert send_message_to_channels(["channel123"], %{}, "SocketId") == :ok

    assert validate :gproc
    assert validate JSEX
    unload JSEX
  end
end
