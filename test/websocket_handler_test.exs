defmodule Poxa.WebsocketHandlerTest do
  use ExUnit.Case, async: true
  alias Poxa.PresenceSubscription
  alias Poxa.PusherEvent
  alias Poxa.Subscription
  alias Poxa.Event
  alias Poxa.Time
  alias Poxa.Channel
  alias Poxa.SocketId
  use Mimic
  import Poxa.WebsocketHandler
  alias Poxa.WebsocketHandler.State

  setup_all do
    :application.set_env(:poxa, :app_secret, "secret")
    :application.set_env(:poxa, :app_key, "app_key")
    :ok
  end

  setup do
    stub(Poxa.registry())
    :ok
  end

  test "normal process message" do
    assert websocket_info({:pid, :msg}, :state) == {:reply, {:text, :msg}, :state}
  end

  test "process message with same socket_id" do
    state = %State{socket_id: :socket_id}

    assert websocket_info({:pid, :msg, :socket_id}, state) == {:ok, state}
  end

  test "process message with different socket_id" do
    state = %State{socket_id: :other_socket_id}

    assert websocket_info({:pid, :msg, :socket_id}, state) == {:reply, {:text, :msg}, state}
  end

  test "special start process message" do
    socket_id = "123.456"
    expect(:cowboy_req, :uri, fn :req, _ -> ["host_url"] end)
    expect(PusherEvent, :connection_established, fn ^socket_id -> :connection_established end)
    expect(SocketId, :generate!, fn -> socket_id end)
    expect(SocketId, :register!, fn ^socket_id -> true end)
    expect(Event, :notify, fn :connected, %{socket_id: ^socket_id, origin: "host_url"} -> :ok end)
    expect(Time, :stamp, fn -> 123 end)

    assert websocket_info(:start, :req) ==
             {:reply, {:text, :connection_established}, %State{socket_id: "123.456", time: 123}}
  end

  test "undefined process message" do
    assert websocket_info(nil, :state) == {:ok, :state}
  end

  test "ping websocket message" do
    assert websocket_handle({:ping, ""}, :state) == {:ok, :state}
  end

  test "undefined pusher event websocket message" do
    expect(Jason, :decode!, fn _ -> %{"event" => "pushernil"} end)

    assert websocket_handle({:text, :undefined_event_json}, :state) == {:ok, :state}
  end

  test "pusher ping event" do
    expect(Jason, :decode!, fn _ -> %{"event" => "pusher:ping"} end)
    expect(PusherEvent, :pong, fn -> :pong end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :ping_json}, state) == {:reply, {:text, :pong}, state}
  end

  test "subscribe private channel event" do
    expect(Jason, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> {:ok, :channel} end)
    expect(PusherEvent, :subscription_succeeded, fn _ -> :subscription_succeeded end)
    expect(Event, :notify, fn :subscribed, %{socket_id: :socket_id, channel: :channel} -> :ok end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, state) ==
             {:reply, {:text, :subscription_succeeded}, state}
  end

  test "subscribe private channel event failing for bad authentication" do
    expect(Jason, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> {:error, :error_message} end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscription_json}, state) ==
             {:reply, {:text, :error_message}, state}
  end

  test "subscribe presence channel event" do
    expect(Jason, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> %PresenceSubscription{channel: :channel} end)
    expect(PusherEvent, :subscription_succeeded, fn _ -> :subscription_succeeded end)
    expect(Event, :notify, fn :subscribed, %{socket_id: :socket_id, channel: :channel} -> :ok end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, state) ==
             {:reply, {:text, :subscription_succeeded}, state}
  end

  test "subscribe presence channel event failing for bad authentication" do
    expect(Jason, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> {:error, :error_message} end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscription_json}, state) ==
             {:reply, {:text, :error_message}, state}
  end

  test "subscribe public channel event" do
    expect(Jason, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> {:ok, :channel} end)
    expect(PusherEvent, :subscription_succeeded, fn _ -> :subscription_succeeded end)
    expect(Event, :notify, fn :subscribed, %{socket_id: :socket_id, channel: :channel} -> :ok end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, state) ==
             {:reply, {:text, :subscription_succeeded}, state}
  end

  test "subscribe event on an already subscribed channel" do
    expect(Jason, :decode!, fn _ -> %{"event" => "pusher:subscribe"} end)
    expect(Subscription, :subscribe!, fn _, _ -> {:ok, :channel} end)
    expect(PusherEvent, :subscription_succeeded, fn _ -> :subscription_succeeded end)
    expect(Event, :notify, fn :subscribed, %{socket_id: :socket_id, channel: :channel} -> :ok end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :subscribe_json}, state) ==
             {:reply, {:text, :subscription_succeeded}, state}
  end

  test "unsubscribe event" do
    expect(Jason, :decode!, fn _ -> %{"event" => "pusher:unsubscribe", "data" => :data} end)
    expect(Subscription, :unsubscribe!, fn :data -> {:ok, :channel} end)

    expect(Event, :notify, fn :unsubscribed, %{socket_id: :socket_id, channel: :channel} ->
      :ok
    end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :unsubscribe_json}, state) == {:ok, state}
  end

  test "client event on presence channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["presence-channel"], name: "client-event"}
    expect(Jason, :decode!, fn :client_event_json -> decoded_json end)
    expect(PusherEvent, :build_client_event, fn ^decoded_json, :socket_id -> {:ok, event} end)
    expect(PusherEvent, :publish, fn _ -> :ok end)
    expect(Channel, :member?, fn _, _ -> true end)

    expect(Event, :notify, fn :client_event_message,
                              %{
                                socket_id: :socket_id,
                                channels: ["presence-channel"],
                                name: "client-event"
                              } ->
      :ok
    end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, state) == {:ok, state}
  end

  test "client event on private channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["private-channel"], name: "client-event"}
    expect(Jason, :decode!, fn :client_event_json -> decoded_json end)
    expect(PusherEvent, :build_client_event, fn ^decoded_json, :socket_id -> {:ok, event} end)
    expect(PusherEvent, :publish, fn _ -> :ok end)
    expect(Channel, :member?, fn _, _ -> true end)

    expect(Event, :notify, fn :client_event_message,
                              %{
                                socket_id: :socket_id,
                                channels: ["private-channel"],
                                name: "client-event"
                              } ->
      :ok
    end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, state) == {:ok, state}
  end

  test "client event on not subscribed private channel" do
    decoded_json = %{"event" => "client-event"}
    event = %PusherEvent{channels: ["private-not-subscribed"], name: "client-event"}
    expect(Jason, :decode!, fn :client_event_json -> decoded_json end)
    expect(PusherEvent, :build_client_event, fn ^decoded_json, :socket_id -> {:ok, event} end)
    expect(Channel, :member?, fn _, _ -> false end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, state) == {:ok, state}
  end

  test "client event on public channel" do
    event = %PusherEvent{channels: ["public-channel"], name: "client-event"}
    expect(Jason, :decode!, fn _ -> %{"event" => "client-event"} end)
    expect(PusherEvent, :build_client_event, fn _, _ -> {:ok, event} end)

    state = %State{socket_id: :socket_id}

    assert websocket_handle({:text, :client_event_json}, state) == {:ok, state}
  end

  describe "websocket_init/1" do
    test "websocket init" do
      expect(:cowboy_req, :binding, fn :app_key, :req -> "app_key" end)
      expect(:cowboy_req, :parse_qs, fn :req -> [{"protocol", "7"}] end)

      assert websocket_init(:req) == {:ok, :req}
      assert_receive :start
    end

    test "websocket init using wrong app_key" do
      expect(:cowboy_req, :binding, fn :app_key, :req -> "different_app_key" end)
      expect(:cowboy_req, :parse_qs, fn :req -> [{"protocol", "7"}] end)

      assert websocket_init(:req) == {:ok, {4001, "Application does not exist"}}
    end

    test "websocket init using protocol higher than 7" do
      expect(:cowboy_req, :binding, fn :app_key, :req -> "app_key" end)
      expect(:cowboy_req, :parse_qs, fn :req -> [{"protocol", "8"}] end)

      assert websocket_init(:req) == {:ok, {4007, "Unsupported protocol version"}}
    end

    test "websocket init using protocol lower than 5" do
      expect(:cowboy_req, :binding, fn :app_key, :req -> "app_key" end)
      expect(:cowboy_req, :parse_qs, fn :req -> [{"protocol", "4"}] end)

      assert websocket_init(:req) == {:ok, {4007, "Unsupported protocol version"}}
    end

    test "websocket init using protocol between 5 and 7" do
      expect(:cowboy_req, :binding, fn :app_key, :req -> "app_key" end)
      expect(:cowboy_req, :parse_qs, fn :req -> [{"protocol", "6"}] end)

      assert websocket_init(:req) == {:ok, :req}
    end
  end

  describe "terminate/3" do
    test "websocket termination" do
      expect(Channel, :all, fn _ -> :channels end)
      expect(Time, :stamp, fn -> 100 end)

      expect(Event, :notify, fn :disconnected,
                                %{socket_id: :socket_id, channels: :channels, duration: 90} ->
        :ok
      end)

      expect(PresenceSubscription, :check_and_remove, fn -> 1 end)
      expect(Poxa.registry(), :clean_up, fn -> :ok end)

      state = %State{socket_id: :socket_id, time: 10}

      assert terminate(:reason, :req, state) == :ok
    end

    test "websocket termination without a socket_id" do
      assert terminate(:reason, :req, nil) == :ok
    end
  end
end
