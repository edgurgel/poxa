defmodule Poxa.Console.WSHandlerTest do
  use ExUnit.Case, async: true
  alias Poxa.Authentication
  alias Poxa.Event
  use Mimic
  import Poxa.Console.WSHandler

  setup do
    stub(Poison, :encode!, &(&1))
    :ok
  end

  describe "websocket_init/3" do
    test "websocket_init with correct signature" do
      expect(:cowboy_req, :method, fn :req -> {:method, :req2} end)
      expect(:cowboy_req, :path, fn :req2 -> {:path, :req3} end)
      expect(:cowboy_req, :qs_vals, fn :req3 -> {:qs_vals, :req4} end)
      expect(Authentication, :check, fn :method, :path, "", :qs_vals -> true end)
      expect(Event, :subscribe, fn -> :ok end)

      assert websocket_init(:tranport, :req, []) == {:ok, :req4, nil}
    end

    test "websocket_init with incorrect signature" do
      expect(:cowboy_req, :method, fn :req -> {:method, :req2} end)
      expect(:cowboy_req, :path, fn :req2 -> {:path, :req3} end)
      expect(:cowboy_req, :qs_vals, fn :req3 -> {:qs_vals, :req4} end)
      expect(Authentication, :check, fn :method, :path, "", :qs_vals -> false end)

      assert websocket_init(:tranport, :req, []) == {:shutdown, :req4}
    end
  end

  describe "websocket_info/3" do
    test "connected" do
      assert {:reply, {:text, msg}, :req, :state} = websocket_info({:internal_event, %{event: :connected, socket_id: "socket_id", origin: "origin"}}, :req, :state)

      assert %{details: "Origin: origin", socket: "socket_id", time: _, type: "Connection"} = msg
    end

    test "disconnected" do
      assert {:reply, {:text, msg}, :req, :state} = websocket_info({:internal_event, %{event: :disconnected, socket_id: "socket_id", channels: ["channel1"], duration: 123}}, :req, :state)

      assert %{details: "Channels: [\"channel1\"], Lifetime: 123s", socket: "socket_id", time: _, type: "Disconnection"} = msg
    end

    test "subscribed" do
      assert {:reply, {:text, msg}, :req, :state} = websocket_info({:internal_event, %{event: :subscribed, socket_id: "socket_id", channel: "channel"}}, :req, :state)

      assert %{details: "Channel: channel", socket: "socket_id", time: _, type: "Subscribed"} = msg
    end

    test "unsubscribed" do
      assert {:reply, {:text, msg}, :req, :state} = websocket_info({:internal_event, %{event: :unsubscribed, socket_id: "socket_id", channel: "channel"}}, :req, :state)

      assert %{details: "Channel: channel", socket: "socket_id", time: _, type: "Unsubscribed"} = msg
    end

    test "api_message" do
      assert {:reply, {:text, msg}, :req, :state} = websocket_info({:internal_event, %{event: :api_message, channels: ["channel"], name: "event_message"}}, :req, :state)

      assert %{details: "Channels: [\"channel\"], Event: event_message", socket: "", time: _, type: "API Message"} = msg
    end

    test "client_event_message" do
      assert {:reply, {:text, msg}, :req, :state} = websocket_info({:internal_event, %{event: :client_event_message, socket_id: "socket_id", channels: ["channel"], name: "event_message"}}, :req, :state)

      assert %{details: "Channels: [\"channel\"], Event: event_message", socket: "socket_id", time: _, type: "Client Event Message"} = msg
    end

    test "member_added" do
      assert {:reply, {:text, msg}, :req, :state} = websocket_info({:internal_event, %{event: :member_added, socket_id: "socket_id", channel: "presence-channel", user_id: "user_id"}}, :req, :state)

      assert %{details: "Channel: \"presence-channel\", UserId: \"user_id\"", socket: "socket_id", time: _, type: "Member added"} = msg
    end

    test "member_removed" do
      assert {:reply, {:text, msg}, :req, :state} = websocket_info({:internal_event, %{event: :member_removed, socket_id: "socket_id", channel: "presence-channel", user_id: "user_id"}}, :req, :state)

      assert %{details: "Channel: \"presence-channel\", UserId: \"user_id\"", socket: "socket_id", time: _, type: "Member removed"} = msg
    end

    test "channel_occupied" do
      assert {:reply, {:text, msg}, :req, :state} = websocket_info({:internal_event, %{event: :channel_occupied, channel: "channel", socket_id: "socket_id"}}, :req, :state)

      assert %{details: "Channel: \"channel\"", socket: "socket_id", time: _, type: "Channel occupied"} = msg
    end


    test "channel_vacated" do
      assert {:reply, {:text, msg}, :req, :state} = websocket_info({:internal_event, %{event: :channel_vacated, channel: "channel", socket_id: "socket_id"}}, :req, :state)

      assert %{details: "Channel: \"channel\"", socket: "socket_id", time: _, type: "Channel vacated"} = msg
    end
  end
end
