defmodule Poxa.ConsoleTest do
  use ExUnit.Case
  import :meck
  import Poxa.Console

  setup_all do
    new JSX
    expect(JSX, :encode!, &(&1))
    on_exit fn -> unload end
    :ok
  end

  test "connected" do
    handle_event(%{event: :connected, socket_id: "socket_id", origin: "origin"}, self)

    assert_received %{details: "Origin: origin", socket: "socket_id", time: _, type: "Connection"}
  end

  test "disconnected" do
    handle_event(%{event: :disconnected, socket_id: "socket_id", channels: ["channel1"], duration: 123}, self)

    assert_received %{details: "Channels: [\"channel1\"], Lifetime: 123s", socket: "socket_id", time: _, type: "Disconnection"}
  end

  test "subscribed" do
    handle_event(%{event: :subscribed, socket_id: "socket_id", channel: "channel"}, self)

    assert_received %{details: "Channel: channel", socket: "socket_id", time: _, type: "Subscribed"}
  end

  test "unsubscribed" do
    handle_event(%{event: :unsubscribed, socket_id: "socket_id", channel: "channel"}, self)

    assert_received %{details: "Channel: channel", socket: "socket_id", time: _, type: "Unsubscribed"}
  end

  test "api_message" do
    handle_event(%{event: :api_message, channels: ["channel"], name: "event_message"}, self)

    assert_received %{details: "Channels: [\"channel\"], Event: event_message", socket: "", time: _, type: "API Message"}
  end

  test "client_event_message" do
    handle_event(%{event: :client_event_message, socket_id: "socket_id", channels: ["channel"], name: "event_message"}, self)

    assert_received %{details: "Channels: [\"channel\"], Event: event_message", socket: "socket_id", time: _, type: "Client Event Message"}
  end

  test "member_added" do
    handle_event(%{event: :member_added, socket_id: "socket_id", channel: "presence-channel", user_id: "user_id"}, self)

    assert_received %{details: "Channel: \"presence-channel\", UserId: \"user_id\"", socket: "socket_id", time: _, type: "Member added"}
  end

  test "member_removed" do
    handle_event(%{event: :member_removed, socket_id: "socket_id", channel: "presence-channel", user_id: "user_id"}, self)

    assert_received %{details: "Channel: \"presence-channel\", UserId: \"user_id\"", socket: "socket_id", time: _, type: "Member removed"}
  end

  test "channel_occupied" do
    handle_event(%{event: :channel_occupied, channel: "channel", socket_id: "socket_id"}, self)

    assert_received %{details: "Channel: \"channel\"", socket: "socket_id", time: _, type: "Channel occupied"}
  end


  test "channel_vacated" do
    handle_event(%{event: :channel_vacated, channel: "channel", socket_id: "socket_id"}, self)

    assert_received %{details: "Channel: \"channel\"", socket: "socket_id", time: _, type: "Channel vacated"}
  end
end
