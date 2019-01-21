defmodule Poxa.WebsocketHandlerTest do
  use ExUnit.Case, async: true
  alias Poxa.PresenceSubscription
  alias Poxa.PusherEvent
  alias Poxa.Subscription
  alias Poxa.Event
  alias Poxa.Time
  alias Poxa.Channel
  alias Poxa.SocketId
  import Mimic
  import Poxa.WebsocketHandler
  alias Poxa.WebsocketHandler.State

  setup_all do
    :application.set_env(:poxa, :app_secret, "secret")
    :application.set_env(:poxa, :app_key, "app_key")
    :ok
  end

  setup do
    stub(Poxa.registry)
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
    socket_id = "123.456"
    expect(:cowboy_req, :host_url, fn :req -> {:host_url, :req2} end)
    expect(PusherEvent, :connection_established, fn ^socket_id -> :connection_established end)
    expect(SocketId, :generate!, fn -> socket_id end)
    expect(SocketId, :register!, fn ^socket_id -> true end)
    expect(Event, :notify, fn :connected, %{socket_id: ^socket_id, origin: :host_url} -> :ok end)
    expect(Time, :stamp, fn -> 123 end)

    assert websocket_info(:start, :req, :state) ==
      {:reply, {:text, :connection_established}, :req2, %State{socket_id: "123.456", time: 123}}
  end

  test "undefined process message" do
    assert websocket_info(nil, :req, :state) == {:ok, :req, :state}
  end

  test "ping websocket message" do
    assert websocket_handle({:ping, ""}, :req, :state) ==
      {:ok, :req, :state}
  end

  test "undefined pusher event websocket message" do
    expect(Poison, :decode!, fn _ -> %{"event" => "pushernil"} end)

    assert websocket_handle({:text, :undefined_event_json}, :req, :state) ==
      {:ok, :req, :state}
  end

  test "pusher ping event" do
    expect(Poison, :decode!, fn _ -> %{"event" => "pusher:ping"} end)
    expect(PusherEvent, :pong, fn -> :pong end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :ping_json}, :req, state) ==
      {:reply, {:text, :pong}, :req, state}
  end

  test "subscribe private channel event" do
    expect(Poison, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> {:ok, :channel} end)
    expect(PusherEvent, :subscription_succeeded, fn _ -> :subscription_succeeded end)
    expect(Event, :notify, fn :subscribed, %{socket_id: :socket_id, channel: :channel} -> :ok end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}
  end

  test "subscribe private channel event failing for bad authentication" do
    expect(Poison, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> {:error, :error_message} end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscription_json}, :req, state) ==
      {:reply, {:text, :error_message}, :req, state}
  end

  test "subscribe presence channel event" do
    expect(Poison, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> %PresenceSubscription{channel: :channel} end)
    expect(PusherEvent, :subscription_succeeded, fn _ -> :subscription_succeeded end)
    expect(Event, :notify, fn :subscribed, %{socket_id: :socket_id, channel: :channel} -> :ok end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}
  end

  test "subscribe presence channel event failing for bad authentication" do
    expect(Poison, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> {:error, :error_message} end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscription_json}, :req, state) ==
      {:reply, {:text, :error_message}, :req, state}
  end

  test "subscribe public channel event" do
    expect(Poison, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> {:ok, :channel} end)
    expect(PusherEvent, :subscription_succeeded, fn _ -> :subscription_succeeded end)
    expect(Event, :notify, fn :subscribed, %{socket_id: :socket_id, channel: :channel} -> :ok end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}
  end

  test "subscribe event on an already subscribed channel" do
    expect(Poison, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> {:ok, :channel} end)
    expect(PusherEvent, :subscription_succeeded, fn _ -> :subscription_succeeded end)
    expect(Event, :notify, fn :subscribed, %{socket_id: :socket_id, channel: :channel} -> :ok end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, :req, state) ==
      {:reply, {:text, :subscription_succeeded}, :req, state}
  end

  test "unsubscribe event" do
    expect(Poison, :decode!, fn _ -> %{"event" => "pusher:unsubscribe", "data" => :data} end)
    expect(Subscription, :unsubscribe!, fn :data -> {:ok, :channel} end)
    expect(Event, :notify, fn :unsubscribed, %{socket_id: :socket_id, channel: :channel} -> :ok end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :unsubscribe_json}, :req, state) ==
      {:ok, :req, state}
  end

  test "client event on presence channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["presence-channel"], name: "client-event"}
    expect(Poison, :decode!, fn :client_event_json -> decoded_json end)
    expect(PusherEvent, :build_client_event, fn ^decoded_json, :socket_id -> {:ok, event} end)
    expect(PusherEvent, :publish, fn _ -> :ok end)
    expect(Channel, :member?, fn _, _ -> true end)
    expect(Event, :notify, fn :client_event_message, %{socket_id: :socket_id, channels: ["presence-channel"], name: "client-event"} -> :ok end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}
  end

  test "client event on private channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["private-channel"], name: "client-event"}
    expect(Poison, :decode!, fn :client_event_json -> decoded_json end)
    expect(PusherEvent, :build_client_event, fn ^decoded_json, :socket_id -> {:ok, event} end)
    expect(PusherEvent, :publish, fn _ -> :ok end)
    expect(Channel, :member?, fn _, _ -> true end)
    expect(Event, :notify, fn :client_event_message, %{socket_id: :socket_id, channels: ["private-channel"], name: "client-event"} -> :ok end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}
  end

  test "client event on not subscribed private channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["private-not-subscribed"], name: "client-event"}
    expect(Poison, :decode!, fn :client_event_json -> decoded_json end)
    expect(PusherEvent, :build_client_event, fn ^decoded_json, :socket_id -> {:ok, event} end)
    expect(Channel, :member?, fn _, _ -> false end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}
  end

  test "client event on public channel" do
    event = %PusherEvent{channels: ["public-channel"], name: "client-event"}
    expect(Poison, :decode!, fn _ -> %{"event" => "client-event"} end)
    expect(PusherEvent, :build_client_event, fn _, _ -> {:ok, event} end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, :req, state) ==
      {:ok, :req, state}
  end

  test "websocket init" do
    expect(:cowboy_req, :binding, fn _, _ -> {"app_key", :req} end)
    expect(:cowboy_req, :qs_val, fn _, _, _ -> {"7", :req} end)
    expect(PusherEvent, :connection_established, fn _ -> :connection_established end)

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, nil}
  end

  test "websocket init using wrong app_key" do
    expect(:cowboy_req, :binding, fn _, _ -> {"different_app_key", :req} end)
    expect(:cowboy_req, :qs_val, fn _, _, _ -> {"7", :req} end)

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, {4001, "Application does not exist"}}
  end

  test "websocket init using protocol higher than 7" do
    expect(:cowboy_req, :binding, fn _, _ -> {"app_key", :req} end)
    expect(:cowboy_req, :qs_val, fn _, _, _ -> {"8", :req} end)

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, {4007, "Unsupported protocol version"}}
  end

  test "websocket init using protocol lower than 5" do
    expect(:cowboy_req, :binding, fn _, _ -> {"app_key", :req} end)
    expect(:cowboy_req, :qs_val, fn _, _, _ -> {"4", :req} end)

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, {4007, "Unsupported protocol version"}}
  end

  test "websocket init using protocol between 5 and 7" do
    expect(:cowboy_req, :binding, fn _, _ -> {"app_key", :req} end)
    expect(:cowboy_req, :qs_val, fn _, _, _ -> {"6", :req} end)

    assert websocket_init(:transport, :req, :opts) == {:ok, :req, nil}
  end

  test "websocket termination" do
    expect(Channel, :all, fn _ -> :channels end)
    expect(Time, :stamp, fn -> 100 end)
    expect(Event, :notify, fn :disconnected, %{socket_id: :socket_id, channels: :channels, duration: 90} -> :ok end)
    expect(PresenceSubscription, :check_and_remove, fn -> 1 end)
    expect(Poxa.registry, :clean_up, fn -> :ok end)

    state = %State{socket_id: :socket_id, time: 10}

    assert websocket_terminate(:reason, :req, state) == :ok
  end

  test "websocket termination without a socket_id" do
    assert websocket_terminate(:reason, :req, nil) == :ok
  end
end
