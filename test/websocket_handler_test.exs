defmodule Poxa.WebsocketHandlerTest do
  use ExUnit.Case
  alias Poxa.PresenceSubscription
  alias Poxa.PusherEvent
  alias Poxa.Subscription
  alias Poxa.Event
  alias Poxa.Time
  alias Poxa.Channel
  alias Poxa.SocketId
  import :meck
  import Poxa.WebsocketHandler
  alias Poxa.WebsocketHandler.State

  setup_all do
    :application.set_env(:poxa, :app_secret, "secret")
    :application.set_env(:poxa, :app_key, "app_key")
    :ok
  end

  setup do
    new Poxa.registry
    on_exit fn -> unload end
    :ok
  end

  test "normal process message" do
    assert websocket_info({:pid, :msg}, :req, :state) ==
      {:reply, {:text, :msg}, :req, :state}
  end

  test "process message with same socket_id" do
    state = %State{socket_id: :socket_id}

    assert websocket_info({:pid, :msg, :socket_id}, :req, state) ==
      {:ok, :req, state}
  end

  test "process message with different socket_id" do
    state = %State{socket_id: :other_socket_id}

    assert websocket_info({:pid, :msg, :socket_id}, :req, state) ==
      {:reply, {:text, :msg}, :req, state}
  end

  test "special start process message" do
    expect(:cowboy_req, :host_url, 1, {:host_url, :req2})
    expect(PusherEvent, :connection_established, 1, :connection_established)
    expect(SocketId, :generate!, 0, "123.456")
    expect(SocketId, :register!, ["123.456"], true)
    expect(Event, :notify, [{[:connected, %{socket_id: "123.456", origin: :host_url}], :ok}])
    expect(Time, :stamp, 0, 123)

    assert websocket_info(:start, :req, :state) ==
      {:reply, {:text, :connection_established}, :req2, %State{socket_id: "123.456", time: 123}}

    assert validate [PusherEvent, Event, SocketId]
  end

  test "undefined process message" do
    assert websocket_info(nil, :req, :state) == {:ok, :req, :state}
  end

  test "ping websocket message" do
    assert websocket_handle({:ping, ""}, :req, :state) ==
      {:ok, :req, :state}
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

    assert validate [JSX, PusherEvent]
  end

  test "subscribe private channel event" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, {:ok, :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    expect(Event, :notify, [{[:subscribed, %{socket_id: :socket_id, channel: :channel}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}

    assert validate [JSX, PusherEvent, Subscription, Event]
  end

  test "subscribe private channel event failing for bad authentication" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, {:error, :error_message})

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscription_json}, :req, state) ==
      {:reply, {:text, :error_message}, :req, state}

    assert validate [JSX, Subscription]
  end

  test "subscribe presence channel event" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, %PresenceSubscription{channel: :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    expect(Event, :notify, [{[:subscribed, %{socket_id: :socket_id, channel: :channel}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}

    assert validate [JSX, PusherEvent, Subscription, Event]
  end

  test "subscribe presence channel event failing for bad authentication" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, {:error, :error_message})

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscription_json}, :req, state) ==
      {:reply, {:text, :error_message}, :req, state}

    assert validate [JSX, Subscription]
  end

  test "subscribe public channel event" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, {:ok, :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    expect(Event, :notify, [{[:subscribed, %{socket_id: :socket_id, channel: :channel}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}

    assert validate [JSX, PusherEvent, Subscription, Event]
  end

  test "subscribe event on an already subscribed channel" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:subscribe"})
    expect(Subscription, :subscribe!, 2, {:ok, :channel})
    expect(PusherEvent, :subscription_succeeded, 1, :subscription_succeeded)
    expect(Event, :notify, [{[:subscribed, %{socket_id: :socket_id, channel: :channel}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}

    assert validate [JSX, PusherEvent, Subscription, Event]
  end

  test "unsubscribe event" do
    expect(JSX, :decode!, 1, %{"event" => "pusher:unsubscribe", "data" => :data})
    expect(Subscription, :unsubscribe!, [{[:data], {:ok, :channel}}])
    expect(Event, :notify, [{[:unsubscribed, %{socket_id: :socket_id, channel: :channel}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :unsubscribe_json}, :req, state) ==
      {:ok, :req, state}

    assert validate [JSX, Subscription, Event]
  end

  test "client event on presence channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["presence-channel"], name: "client-event"}
    expect(JSX, :decode!, [{[:client_event_json], decoded_json}])
    expect(PusherEvent, :build_client_event, [{[decoded_json, :socket_id], {:ok, event}}])
    expect(PusherEvent, :publish, 1, :ok)
    expect(Channel, :member?, 2, true)
    expect(Event, :notify, [{[:client_event_message, %{socket_id: :socket_id, channels: ["presence-channel"], name: "client-event"}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}

    assert validate [JSX, PusherEvent, Event]
  end

  test "client event on private channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["private-channel"], name: "client-event"}
    expect(JSX, :decode!, [{[:client_event_json], decoded_json}])
    expect(PusherEvent, :build_client_event, [{[decoded_json, :socket_id], {:ok, event}}])
    expect(PusherEvent, :publish, 1, :ok)
    expect(Channel, :member?, 2, true)
    expect(Event, :notify, [{[:client_event_message, %{socket_id: :socket_id, channels: ["private-channel"], name: "client-event"}], :ok}])

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}

    assert validate [JSX, PusherEvent, Event]
  end

  test "client event on not subscribed private channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["private-not-subscribed"], name: "client-event"}
    expect(JSX, :decode!, [{[:client_event_json], decoded_json}])
    expect(PusherEvent, :build_client_event, [{[decoded_json, :socket_id], {:ok, event}}])
    expect(Channel, :member?, 2, false)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}

    assert validate [JSX, PusherEvent, Channel]
  end

  test "client event on public channel" do
    event = %PusherEvent{channels: ["public-channel"], name: "client-event"}
    expect(JSX, :decode!, 1, %{"event" => "client-event"})
    expect(PusherEvent, :build_client_event, 2, {:ok, event})

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}

    assert validate [JSX, PusherEvent]
  end

  test "websocket init" do
    expect(:cowboy_req, :binding, 2, {"app_key", :req})
    expect(:cowboy_req, :qs_val, 3, {"7", :req})
    expect(PusherEvent, :connection_established, 1, :connection_established)

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, nil}

    assert validate [:cowboy_req, PusherEvent]
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
    expect(PresenceSubscription, :check_and_remove, 0, 1)
    expect(Poxa.registry, :clean_up, 0, :ok)

    state = %State{socket_id: :socket_id, time: 10}

    assert websocket_terminate(:reason, :req, state) == :ok

    assert validate [Event, PresenceSubscription, Poxa.registry]
  end

  test "websocket termination without a socket_id" do
    assert websocket_terminate(:reason, :req, nil) == :ok
  end
end
