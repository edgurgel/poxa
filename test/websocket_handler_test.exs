defmodule Poxa.WebsocketHandlerTest do
  use ExUnit.Case
  alias Poxa.Authentication
  alias Poxa.PresenceSubscription
  alias Poxa.PusherEvent
  alias Poxa.Subscription
  alias Poxa.Console
  import :meck
  import Poxa.WebsocketHandler

  setup do
    new PusherEvent
    new Authentication
    new Subscription
    new PresenceSubscription
    new Console
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
    unload Console
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
    expect(:cowboy_req, :host_url, 1, {:host_url, :req2})
    expect(PusherEvent, :connection_established, 1, :connection_established)
    expect(Console, :connected, 2, :ok)

    assert websocket_info(:start, :req, :state) ==
      {:reply, {:text, :connection_established}, :req2, "uuid"}

    assert validate PusherEvent
    assert validate Console
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
    expect(Console, :subscribed, 2, :ok)

    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}

    assert validate JSEX
    assert validate :application
    assert validate PusherEvent
    assert validate Subscription
    assert validate Console
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
    expect(Console, :subscribed, 2, :ok)

    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}

    assert validate JSEX
    assert validate :application
    assert validate PusherEvent
    assert validate Subscription
    assert validate Console
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
    expect(Console, :subscribed, 2, :ok)

    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}

    assert validate JSEX
    assert validate PusherEvent
    assert validate Subscription
    assert validate Console
  end

  test "subscribe event on an already subscribed channel" do
    expect(JSEX, :decode!, 1, [{"event", "pusher:subscribe"}])
    expect(Subscription, :subscribe!, 2, {:ok, :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    expect(Console, :subscribed, 2, :ok)

    assert websocket_handle({:text, :subscribe_json}, :req, :socket_id) ==
      {:reply, {:text, :subscription_succeeded}, :req, :socket_id}

    assert validate JSEX
    assert validate PusherEvent
    assert validate Subscription
    assert validate Console
  end

  test "unsubscribe event" do
    expect(JSEX, :decode!, 1, [{"event", "pusher:unsubscribe"}])
    expect(Subscription, :unsubscribe!, 1, {:ok, :channel})
    expect(Console, :unsubscribed, 2, :ok)

    assert websocket_handle({:text, :unsubscribe_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}

    assert validate JSEX
    assert validate Subscription
    assert validate Console
  end

  test "client event on presence channel" do
    expect(JSEX, :decode!, 1, [{"event", "client-event"}])
    expect(PusherEvent, :parse_channels, 1, {:message, ["presence-channel", "public-channel"], nil})
    expect(PusherEvent, :send_message_to_channel, 3, :ok)
    expect(Subscription, :subscribed?, 1, true)
    expect(Console, :client_event_message, [{[:socket_id, ["presence-channel"], :message], :ok}])

    assert websocket_handle({:text, :client_event_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}

    assert validate JSEX
    assert validate PusherEvent
    assert validate Subscription
    assert Console
  end

  test "client event on private channel" do
    expect(JSEX, :decode!, 1, [{"event", "client-event"}])
    expect(PusherEvent, :parse_channels, 1, {:message, ["private-channel"], nil})
    expect(PusherEvent, :send_message_to_channel, 3, :ok)
    expect(Subscription, :subscribed?, 1, true)
    expect(Console, :client_event_message, [{[:socket_id, ["private-channel"], :message], :ok}])

    assert websocket_handle({:text, :client_event_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}

    assert validate JSEX
    assert validate PusherEvent
    assert validate Subscription
    assert validate Console
  end

  test "client event on not subscribed private channel" do
    expect(JSEX, :decode!, 1, [{"event", "client-event"}])
    expect(PusherEvent, :parse_channels, 1, {:message, ["private-subscribed-channel", "private-not-subscribed"], nil})
    expect(PusherEvent, :send_message_to_channel, 3, :ok)
    expect(Subscription, :subscribed?, [{["private-subscribed-channel"], true},
                                        {["private-not-subscribed"], false}])
    expect(Console, :client_event_message, [{[:socket_id, ["private-subscribed-channel"], :message], :ok}])

    assert websocket_handle({:text, :client_event_json}, :req, :socket_id) ==
      {:ok, :req, :socket_id}

    assert validate JSEX
    assert validate PusherEvent
    assert validate Subscription
    assert validate Console
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
    expect(:cowboy_req, :qs_val, 3, {"7", :req})
    expect(PusherEvent, :connection_established, 1, :connection_established)

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, nil}

    assert validate :application
    assert validate :cowboy_req
    assert validate PusherEvent
  end

  test "websocket init using wrong app_key" do
    expect(:application, :get_env, 2, {:ok, "app_key"})
    expect(:cowboy_req, :binding, 2, {"different_app_key", :req})
    expect(:cowboy_req, :qs_val, 3, {"7", :req})

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, {4001, "Application does not exist"}}

    assert validate :application
    assert validate :cowboy_req
  end

  test "websocket init using protocol higher than 7" do
    expect(:application, :get_env, 2, {:ok, "app_key"})
    expect(:cowboy_req, :binding, 2, {"app_key", :req})
    expect(:cowboy_req, :qs_val, 3, {"8", :req})

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, {4007, "Unsupported protocol version"}}

    assert validate :application
    assert validate :cowboy_req
  end

  test "websocket init using protocol lower than 5" do
    expect(:application, :get_env, 2, {:ok, "app_key"})
    expect(:cowboy_req, :binding, 2, {"app_key", :req})
    expect(:cowboy_req, :qs_val, 3, {"4", :req})

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, {4007, "Unsupported protocol version"}}

    assert validate :application
    assert validate :cowboy_req
  end

  test "websocket init using protocol between 5 and 7" do
    expect(:application, :get_env, 2, {:ok, "app_key"})
    expect(:cowboy_req, :binding, 2, {"app_key", :req})
    expect(:cowboy_req, :qs_val, 3, {"6", :req})

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, nil}

    assert validate :application
    assert validate :cowboy_req
  end

  test "websocket termination" do
    expect(Subscription, :channels, 1, :channels)
    expect(Console, :disconnected, [{[:socket_id, :channels], :ok}])
    expect(PresenceSubscription, :check_and_remove, 0, :ok)
    expect(:gproc, :goodbye, 0, :ok)

    assert websocket_terminate(:reason, :req, :socket_id) == :ok

    assert validate Subscription
    assert validate Console
    assert validate PresenceSubscription
    assert validate :gproc
  end

  test "websocket termination without a socket_id" do
    assert websocket_terminate(:reason, :req, nil) == :ok
  end

end
