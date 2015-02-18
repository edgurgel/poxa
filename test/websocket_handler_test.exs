defmodule Poxa.WebsocketHandlerTest do
  use ExUnit.Case
  alias Poxa.Authentication
  alias Poxa.PresenceSubscription
  alias Poxa.PusherEvent
  alias Poxa.Subscription
  alias Poxa.Event
  alias Poxa.Time
  alias Poxa.Channel
  import :meck
  import Poxa.WebsocketHandler
  alias Poxa.WebsocketHandler.State

  setup_all do
    :application.set_env(:poxa, :app_secret, "secret")
    :application.set_env(:poxa, :app_key, "app_key")
    :ok
  end

  setup do
    new PusherEvent
    new Authentication
    new Subscription
    new PresenceSubscription
    new Event
    new Time
    new JSX
    new :gproc
    new :uuid
    new :cowboy_req
    on_exit fn -> unload end
    :ok
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
    expect(Event, :notify, [{[:connected, %{socket_id: "uuid", origin: :host_url}], :ok}])
    expect(Time, :stamp, 0, 123)

    assert websocket_info(:start, :req, :state) ==
      {:reply, {:text, :connection_established}, :req2, %State{socket_id: "uuid", time: 123}}

    assert validate PusherEvent
    assert validate Event
    assert validate :uuid
    assert validate :gproc
    assert validate JSX
  end

  test "undefined process message" do
    assert websocket_info(nil, :req, :state) == {:ok, :req, :state}
  end

  test "undefined pusher event websocket message" do
    expect(JSX, :decode!, 1, %{"event" => "pushernil"})

    assert websocket_handle({:text, :undefined_event_json}, :req, :state) ==
      {:ok, :req, :state}

    assert validate JSX
  end

  test "pusher ping event" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:ping"})
    expect(PusherEvent, :pong, 0, :pong)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :ping_json}, :req, state) ==
      {:reply, {:text, :pong}, :req, state}

    assert validate JSX
    assert validate PusherEvent
  end

  test "subscribe private channel event" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, {:ok, :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    expect(Event, :notify, [{[:subscribed, %{socket_id: :socket_id, channel: :channel}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}

    assert validate JSX
    assert validate PusherEvent
    assert validate Subscription
    assert validate Event
  end

  test "subscribe private channel event failing for bad authentication" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, :error)
    expect(PusherEvent, :subscription_error, 0, :subscription_error)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscription_json}, :req, state) ==
      {:reply, {:text, :subscription_error}, :req, state}

    assert validate JSX
    assert validate PusherEvent
    assert validate Subscription
  end

  test "subscribe presence channel event" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, %PresenceSubscription{channel: :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    expect(Event, :notify, [{[:subscribed, %{socket_id: :socket_id, channel: :channel}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}

    assert validate JSX
    assert validate PusherEvent
    assert validate Subscription
    assert validate Event
  end

  test "subscribe presence channel event failing for bad authentication" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, :error)
    expect(PusherEvent, :subscription_error, 0, :subscription_error)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscription_json}, :req, state) ==
      {:reply, {:text, :subscription_error}, :req, state}

    assert validate JSX
    assert validate PusherEvent
    assert validate Subscription
  end

  test "subscribe public channel event" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, {:ok, :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    expect(Event, :notify, [{[:subscribed, %{socket_id: :socket_id, channel: :channel}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}

    assert validate JSX
    assert validate PusherEvent
    assert validate Subscription
    assert validate Event
  end

  test "subscribe event on an already subscribed channel" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, {:ok, :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    expect(Event, :notify, [{[:subscribed, %{socket_id: :socket_id, channel: :channel}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}

    assert validate JSX
    assert validate PusherEvent
    assert validate Subscription
    assert validate Event
  end

  test "unsubscribe event" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:unsubscribe", "data" => :data})
    expect(Subscription, :unsubscribe!, [{[:data], {:ok, :channel}}])
    expect(Event, :notify, [{[:unsubscribed, %{socket_id: :socket_id, channel: :channel}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :unsubscribe_json}, :req, state) ==
      {:ok, :req, state}

    assert validate JSX
    assert validate Subscription
    assert validate Event
  end

  test "client event on presence channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["presence-channel"], name: "client-event"}
    expect(JSX, :decode!, [{[:client_event_json], decoded_json}])
    expect(PusherEvent, :build_client_event, [{[decoded_json, :socket_id], event}])
    expect(PusherEvent, :publish, 1, :ok)
    expect(Channel, :subscribed?, 2, true)
    expect(Event, :notify, [{[:client_event_message, %{socket_id: :socket_id, channels: ["presence-channel"], name: "client-event"}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}

    assert validate JSX
    assert validate PusherEvent
    assert validate Channel
    assert validate Event
  end

  test "client event on private channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["private-channel"], name: "client-event"}
    expect(JSX, :decode!, [{[:client_event_json], decoded_json}])
    expect(PusherEvent, :build_client_event, [{[decoded_json, :socket_id], event}])
    expect(PusherEvent, :publish, 1, :ok)
    expect(Channel, :subscribed?, 2, true)
    expect(Event, :notify, [{[:client_event_message, %{socket_id: :socket_id, channels: ["private-channel"], name: "client-event"}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}

    assert validate JSX
    assert validate PusherEvent
    assert validate Channel
    assert validate Event
  end

  test "client event on not subscribed private channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["private-not-subscribed"], name: "client-event"}
    expect(JSX, :decode!, [{[:client_event_json], decoded_json}])
    expect(PusherEvent, :build_client_event, [{[decoded_json, :socket_id], event}])
    expect(Channel, :subscribed?, 2, false)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}

    assert validate JSX
    assert validate PusherEvent
    assert validate Channel
    assert validate Event
  end

  test "client event on public channel" do
    event = %PusherEvent{channels: ["public-channel"], name: "client-event"}
    expect(JSX, :decode!, 1, %{"event" => "client-event"})
    expect(PusherEvent, :build_client_event, 2, event)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}

    assert validate JSX
    assert validate PusherEvent
  end

  test "websocket init" do
    expect(:cowboy_req, :binding, 2, {"app_key", :req})
    expect(:cowboy_req, :qs_val, 3, {"7", :req})
    expect(PusherEvent, :connection_established, 1, :connection_established)

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, nil}

    assert validate :cowboy_req
    assert validate PusherEvent
  end

  test "websocket init using wrong app_key" do
    expect(:cowboy_req, :binding, 2, {"different_app_key", :req})
    expect(:cowboy_req, :qs_val, 3, {"7", :req})

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, {4001, "Application does not exist"}}

    assert validate :cowboy_req
  end

  test "websocket init using protocol higher than 7" do
    expect(:cowboy_req, :binding, 2, {"app_key", :req})
    expect(:cowboy_req, :qs_val, 3, {"8", :req})

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, {4007, "Unsupported protocol version"}}

    assert validate :cowboy_req
  end

  test "websocket init using protocol lower than 5" do
    expect(:cowboy_req, :binding, 2, {"app_key", :req})
    expect(:cowboy_req, :qs_val, 3, {"4", :req})

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, {4007, "Unsupported protocol version"}}

    assert validate :cowboy_req
  end

  test "websocket init using protocol between 5 and 7" do
    expect(:cowboy_req, :binding, 2, {"app_key", :req})
    expect(:cowboy_req, :qs_val, 3, {"6", :req})

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, nil}

    assert validate :cowboy_req
  end

  test "websocket termination" do
    expect(Channel, :all, 1, :channels)
    expect(Time, :stamp, 0, 100)
    expect(Event, :notify, [{[:disconnected, %{socket_id: :socket_id, channels: :channels, duration: 90}], :ok}])
    expect(PresenceSubscription, :check_and_remove, 0, :ok)
    expect(:gproc, :goodbye, 0, :ok)

    state = %State{socket_id: :socket_id, time: 10}

    assert websocket_terminate(:reason, :req, state) == :ok

    assert validate Subscription
    assert validate Event
    assert validate PresenceSubscription
    assert validate :gproc
  end

  test "websocket termination without a socket_id" do
    assert websocket_terminate(:reason, :req, nil) == :ok
  end
end
