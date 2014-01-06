Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.WebsocketHandlerTest do
  use ExUnit.Case
  alias Poxa.Authentication
  alias Poxa.PresenceSubscription
  alias Poxa.PusherEvent
  alias Poxa.Subscription
  import :meck
  import Poxa.WebsocketHandler

  setup do
    new PusherEvent
    new Authentication
    new Subscription
    new PresenceSubscription
    new :application, [:unstick]
    new JSEX
    new :gproc
    new :uuid
    new :cowboy_req
  end

  teardown do
    unload PusherEvent
    unload Authentication
    unload Subscription
    unload PresenceSubscription
    unload :application
    unload JSEX
    unload :gproc
    unload :uuid
    unload :cowboy_req
  end

  test "normal process message" do
    assert websocket_info({:pid, :msg}, :req, :state) ==
      {:reply, {:text, :msg}, :req, :state}
  end

  test "special start process message" do
    expect(:uuid, :uuid1, fn -> passthrough([]) end)
    expect(:uuid, :to_string, 1, 'uuid')
    expect(:gproc, :reg, 1, :registered)
    expect(PusherEvent, :connection_established, 1, :connection_established)
    assert websocket_info(:start, :req, :state) ==
      {:reply, {:text, :connection_established}, :req, "uuid"}
    assert validate PusherEvent
    assert validate :uuid
    assert validate :gproc
    assert validate JSEX
  end

  test "undefined process message" do
    assert websocket_info(nil, :req, :state) == {:ok, :req, :state}
  end

  test "undefined pusher event websocket message" do
    expect(JSEX, :decode!, 1, [{"event", "pushernil"}])
    assert websocket_handle({:text, :undefined_event_jon}, :req, :state) ==
      {:ok, :req, :state}
    assert validate JSEX
  end

  test "pusher ping event" do
    expect(JSEX, :decode!, 1, [{"event", "pusher:ping"}])
    expect(PusherEvent, :pong, 0, :pong)
    assert websocket_handle({:text, :ping_json}, :req, :state) ==
      {:reply, {:text, :pong}, :req, :state}
    assert validate JSEX
    assert validate PusherEvent
  end

  test "subscribe private channel event" do
    expect(:application, :get_env, 2, "secret")
    expect(JSEX, :decode!, 1, [{"event", "pusher:subscribe"}])
    expect(Subscription, :subscribe!, 2, {:ok, :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}
    assert validate JSEX
    assert validate :application
    assert validate PusherEvent
    assert validate Subscription
  end

  test "subscribe private channel event failing for bad authentication" do
    expect(:application, :get_env, 2, "secret")
    expect(JSEX, :decode!, 1, [{"event", "pusher:subscribe"}])
    expect(Subscription, :subscribe!, 2, :error)
    expect(PusherEvent, :subscription_error, 0, :subscription_error)
    assert websocket_handle({:text, :subscription_json}, :req, :state) ==
      {:reply, {:text, :subscription_error}, :req, :state}
    assert validate JSEX
    assert validate :application
    assert validate PusherEvent
    assert validate Subscription
  end

  test "subscribe presence channel event" do
    expect(:application, :get_env, 2, "secret")
    expect(JSEX, :decode!, 1, [{"event", "pusher:subscribe"}])
    expect(Subscription, :subscribe!, 2, {:presence, :channel, :data})
    expect(PusherEvent, :presence_subscription_succeeded, 2, :subscription_succeeded)
    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}
    assert validate JSEX
    assert validate :application
    assert validate PusherEvent
    assert validate Subscription
  end

  test "subscribe presence channel event failing for bad authentication" do
    expect(:application, :get_env, 2, "secret")
    expect(JSEX, :decode!, 1, [{"event", "pusher:subscribe"}])
    expect(Subscription, :subscribe!, 2, :error)
    expect(PusherEvent, :subscription_error, 0, :subscription_error)
    assert websocket_handle({:text, :subscription_json}, :req, :state) ==
      {:reply, {:text, :subscription_error}, :req, :state}
    assert validate JSEX
    assert validate :application
    assert validate PusherEvent
    assert validate Subscription
  end

  test "subscribe public channel event" do
    expect(JSEX, :decode!, 1, [{"event", "pusher:subscribe"}])
    expect(Subscription, :subscribe!, 2, {:ok, :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}
    assert validate JSEX
    assert validate PusherEvent
    assert validate Subscription
  end

  test "subscribe event on an already subscribed channel" do
    expect(JSEX, :decode!, 1, [{"event", "pusher:subscribe"}])
    expect(Subscription, :subscribe!, 2, {:ok, :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}
    assert validate JSEX
    assert validate PusherEvent
    assert validate Subscription
  end

  test "unsubscribe event" do
    expect(JSEX, :decode!, 1, [{"event", "pusher:unsubscribe"}])
    expect(Subscription, :unsubscribe!, 1, :ok)
    assert websocket_handle({:text, :unsubscribe_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}
    assert validate JSEX
    assert validate Subscription
  end

  test "client event on presence channel" do
    expect(JSEX, :decode!, 1, [{"event", "client-event"}])
    expect(PusherEvent, :parse_channels, 1, {:message, ["presence-channel"], nil})
    expect(PusherEvent, :send_message_to_channel, 3, :ok)
    expect(Subscription, :subscribed?, 1, true)
    assert websocket_handle({:text, :client_event_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}
    assert validate JSEX
    assert validate PusherEvent
    assert validate Subscription
  end

  test "client event on private channel" do
    expect(JSEX, :decode!, 1, [{"event", "client-event"}])
    expect(PusherEvent, :parse_channels, 1, {:message, ["private-channel"], nil})
    expect(PusherEvent, :send_message_to_channel, 3, :ok)
    expect(Subscription, :subscribed?, 1, true)
    assert websocket_handle({:text, :client_event_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}
    assert validate JSEX
    assert validate PusherEvent
    assert validate Subscription
  end

  test "client event on public channel" do
    expect(JSEX, :decode!, 1, [{"event", "client-event"}])
    expect(PusherEvent, :parse_channels, 1, {:message, ["public-channel"], nil})
    assert websocket_handle({:text, :client_event_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}
    assert validate JSEX
    assert validate PusherEvent
  end

  test "websocket init" do
    expect(:application, :get_env, 2, {:ok, "app_key"})
    expect(:cowboy_req, :binding, 2, {"app_key", :req})
    expect(PusherEvent, :connection_established, 1, :connection_established)
    assert websocket_init(:transport, :req, :opts) == {:ok, :req, nil}
    assert validate :application
    assert validate :cowboy_req
    assert validate PusherEvent
  end

  test "websocket init using wrong app_key" do
    expect(:application, :get_env, 2, {:ok, "app_key"})
    expect(:cowboy_req, :binding, 2, {"different_app_key", :req})
    assert websocket_init(:transport, :req, :opts) == {:shutdown, :req}
    assert validate :application
    assert validate :cowboy_req
  end

  test "websocket termination" do
    expect(PresenceSubscription, :check_and_remove, 0, :ok)
    expect(:gproc, :goodbye, 0, :ok)
    assert websocket_terminate(:reason, :req, :state) == :ok
    assert validate PresenceSubscription
    assert validate :gproc
  end

end
