Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.WebsocketHandlerTest do
  use ExUnit.Case
  import Poxa.WebsocketHandler
  alias Poxa.Authentication
  alias Poxa.PresenceSubscription
  alias Poxa.PusherEvent
  alias Poxa.Subscription

  setup do
    :meck.new PusherEvent
    :meck.new Authentication
    :meck.new Subscription
    :meck.new PresenceSubscription
    :meck.new :application, [:unstick]
    :meck.new :jsx
    :meck.new :gproc
    :meck.new :uuid
    :meck.new :cowboy_req
  end

  teardown do
    :meck.unload PusherEvent
    :meck.unload Authentication
    :meck.unload Subscription
    :meck.unload PresenceSubscription
    :meck.unload :application
    :meck.unload :jsx
    :meck.unload :gproc
    :meck.unload :uuid
    :meck.unload :cowboy_req
  end

  test "normal process message" do
    assert websocket_info({:pid, :msg}, :req, :state) ==
      {:reply, {:text, :msg}, :req, :state}
  end

  test "special start process message" do
    :meck.expect(:jsx, :encode, 1, :encoded_data)
    :meck.expect(:uuid, :uuid1, fn -> :meck.passthrough([]) end)
    :meck.expect(:uuid, :to_string, 1, 'uuid')
    :meck.expect(:gproc, :reg, 1, :registered)
    :meck.expect(PusherEvent, :connection_established, 1, :connection_established)
    assert websocket_info(:start, :req, :state) ==
      {:reply, {:text, :connection_established}, :req, "uuid"}
    assert :meck.validate PusherEvent
    assert :meck.validate :uuid
    assert :meck.validate :gproc
    assert :meck.validate :jsx
  end

  test "undefined process message" do
    assert websocket_info(nil, :req, :state) == {:ok, :req, :state}
  end

  test "undefined pusher event websocket message" do
    :meck.expect(:jsx, :decode, 1, [{"event", "pushernil"}])
    assert websocket_handle({:text, :undefined_event_jon}, :req, :state) ==
      {:ok, :req, :state}
    assert :meck.validate :jsx
  end

  test "pusher ping event" do
    :meck.expect(:jsx, :decode, 1, [{"event", "pusher:ping"}])
    :meck.expect(PusherEvent, :pong, 0, :pong)
    assert websocket_handle({:text, :ping_json}, :req, :state) ==
      {:reply, {:text, :pong}, :req, :state}
    assert :meck.validate :jsx
    assert :meck.validate PusherEvent
  end

  test "subscribe private channel event" do
    :meck.expect(:application, :get_env, 2, "secret")
    :meck.expect(:jsx, :decode, 1, [{"event", "pusher:subscribe"}])
    :meck.expect(Subscription, :subscribe!, 2, :ok)
    :meck.expect(PusherEvent, :subscription_succeeded, 0, :subscription_succeeded)
    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}
    assert :meck.validate :jsx
    assert :meck.validate :application
    assert :meck.validate PusherEvent
    assert :meck.validate Subscription
  end

  test "subscribe private channel event failing for bad authentication" do
    :meck.expect(:application, :get_env, 2, "secret")
    :meck.expect(:jsx, :decode, 1, [{"event", "pusher:subscribe"}])
    :meck.expect(Subscription, :subscribe!, 2, :error)
    :meck.expect(PusherEvent, :subscription_error, 0, :subscription_error)
    assert websocket_handle({:text, :subscription_json}, :req, :state) ==
      {:reply, {:text, :subscription_error}, :req, :state}
    assert :meck.validate :jsx
    assert :meck.validate :application
    assert :meck.validate PusherEvent
    assert :meck.validate Subscription
  end

  test "subscribe presence channel event" do
    :meck.expect(:application, :get_env, 2, "secret")
    :meck.expect(:jsx, :decode, 1, [{"event", "pusher:subscribe"}])
    :meck.expect(Subscription, :subscribe!, 2, {:presence, :channel, :data})
    :meck.expect(PusherEvent, :presence_subscription_succeeded, 2, :subscription_succeeded)
    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}
    assert :meck.validate :jsx
    assert :meck.validate :application
    assert :meck.validate PusherEvent
    assert :meck.validate Subscription
  end

  test "subscribe presence channel event failing for bad authentication" do
    :meck.expect(:application, :get_env, 2, "secret")
    :meck.expect(:jsx, :decode, 1, [{"event", "pusher:subscribe"}])
    :meck.expect(Subscription, :subscribe!, 2, :error)
    :meck.expect(PusherEvent, :subscription_error, 0, :subscription_error)
    assert websocket_handle({:text, :subscription_json}, :req, :state) ==
      {:reply, {:text, :subscription_error}, :req, :state}
    assert :meck.validate :jsx
    assert :meck.validate :application
    assert :meck.validate PusherEvent
    assert :meck.validate Subscription
  end

  test "subscribe public channel event" do
    :meck.expect(:jsx, :decode, 1, [{"event", "pusher:subscribe"}])
    :meck.expect(Subscription, :subscribe!, 2, :ok)
    :meck.expect(PusherEvent, :subscription_succeeded, 0, :subscription_succeeded)
    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}
    assert :meck.validate :jsx
    assert :meck.validate PusherEvent
    assert :meck.validate Subscription
  end

  test "subscribe event on an already subscribed channel" do
    :meck.expect(:jsx, :decode, 1, [{"event", "pusher:subscribe"}])
    :meck.expect(Subscription, :subscribe!, 2, :ok)
    :meck.expect(PusherEvent, :subscription_succeeded, 0, :subscription_succeeded)
    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}
    assert :meck.validate :jsx
    assert :meck.validate PusherEvent
    assert :meck.validate Subscription
  end

  test "unsubscribe event" do
    :meck.expect(:jsx, :decode, 1, [{"event", "pusher:unsubscribe"}])
    :meck.expect(Subscription, :unsubscribe!, 1, :ok)
    assert websocket_handle({:text, :unsubscribe_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}
    assert :meck.validate :jsx
    assert :meck.validate Subscription
  end

  test "client event on presence channel" do
    :meck.expect(:jsx, :decode, 1, [{"event", "client-event"}])
    :meck.expect(PusherEvent, :parse_channels, 1, {:message, ["presence-channel"], nil})
    :meck.expect(PusherEvent, :send_message_to_channel, 3, :ok)
    :meck.expect(Subscription, :subscribed?, 1, true)
    assert websocket_handle({:text, :client_event_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}
    assert :meck.validate :jsx
    assert :meck.validate PusherEvent
    assert :meck.validate Subscription
  end

  test "client event on private channel" do
    :meck.expect(:jsx, :decode, 1, [{"event", "client-event"}])
    :meck.expect(PusherEvent, :parse_channels, 1, {:message, ["private-channel"], nil})
    :meck.expect(PusherEvent, :send_message_to_channel, 3, :ok)
    :meck.expect(Subscription, :subscribed?, 1, true)
    assert websocket_handle({:text, :client_event_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}
    assert :meck.validate :jsx
    assert :meck.validate PusherEvent
    assert :meck.validate Subscription
  end

  test "client event on public channel" do
    :meck.expect(:jsx, :decode, 1, [{"event", "client-event"}])
    :meck.expect(PusherEvent, :parse_channels, 1, {:message, ["public-channel"], nil})
    assert websocket_handle({:text, :client_event_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}
    assert :meck.validate :jsx
    assert :meck.validate PusherEvent
  end

  test "websocket init" do
    :meck.expect(:application, :get_env, 2, {:ok, "app_key"})
    :meck.expect(:cowboy_req, :binding, 2, {"app_key", :req})
    :meck.expect(PusherEvent, :connection_established, 1, :connection_established)
    assert websocket_init(:transport, :req, :opts) == {:ok, :req, nil}
    assert :meck.validate :application
    assert :meck.validate :cowboy_req
    assert :meck.validate PusherEvent
  end


  test "websocket init using wrong app_key" do
    :meck.expect(:application, :get_env, 2, {:ok, "app_key"})
    :meck.expect(:cowboy_req, :binding, 2, {"different_app_key", :req})
    assert websocket_init(:transport, :req, :opts) == {:shutdown, :req, nil}
    assert :meck.validate :application
    assert :meck.validate :cowboy_req
  end

  test "websocket termination" do
    :meck.expect(PresenceSubscription, :check_and_remove, 0, :ok)
    assert websocket_terminate(:reason, :req, :state) == :ok
    :meck.validate PresenceSubscription
  end

end
