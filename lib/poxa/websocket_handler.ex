defmodule Poxa.WebsocketHandler do
  @behaviour :cowboy_websocket_handler
  @moduledoc """
  This module contains Cowboy Websocket handler callbacks to requests on /apps/:app_key

  More info on Cowboy HTTP handler at: http://ninenines.eu/docs/en/cowboy/HEAD/guide/ws_handlers

  More info on Pusher protocol at: http://pusher.com/docs/pusher_protocol
  """
  require Logger
  alias Poxa.PusherEvent
  alias Poxa.Event
  alias Poxa.PresenceSubscription
  alias Poxa.Subscription
  alias Poxa.Channel
  alias Poxa.Time
  alias Poxa.SocketId

  @max_protocol 7
  @min_protocol 5

  defmodule State do
    defstruct [:socket_id, :time]
  end

  @doc false
  def init(_transport, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  @doc """
  This function checks for proper app_key and protocol before continuing
  It can return 4007 code if the protocol is wrong or 4001 if the app key is incorrect
  """
  def websocket_init(_transport_name, req, _opts) do
    {app_key, req} = :cowboy_req.binding(:app_key, req)
    {protocol, req} = :cowboy_req.qs_val("protocol", req, to_string(@max_protocol))
    case :application.get_env(:poxa, :app_key) do
      {:ok, ^app_key} ->
        if supported_protocol?(protocol) do
          send self, :start
          {:ok, req, nil}
        else
          Logger.error "Protocol #{protocol} not supported"
          send self, :start_error
          {:ok, req, {4007, "Unsupported protocol version"}}
        end
      {:ok, expected_app_key} ->
        Logger.error "Invalid app_key, expected #{expected_app_key}, found #{app_key}"
          send self, :start_error
          {:ok, req, {4001, "Application does not exist"}}
    end
  end

  defp supported_protocol?(protocol) do
    try do
      protocol = String.to_integer(protocol)
      protocol >= @min_protocol and protocol <= @max_protocol
    rescue
      ArgumentError -> false
    end
  end

  @doc """
  The handle function can receive the following requests:

  * pusher:subscribe
  * pusher:unsubscribe
  * pusher:ping
  * client-* event

  More info: http://pusher.com/docs/pusher_protocol
  """
  def websocket_handle({:text, json}, req, state) do
    JSX.decode!(json) |> handle_pusher_event(req, state)
  end
  def websocket_handle({:ping, _}, req, state), do: { :ok, req, state }

  defp handle_pusher_event(decoded_json, req, state) do
    handle_pusher_event(decoded_json["event"], decoded_json, req, state)
  end

  defp handle_pusher_event("pusher:subscribe", decoded_json, req, %State{socket_id: socket_id} = state) do
    data = decoded_json["data"]
    reply = case Subscription.subscribe!(data, socket_id) do
      {:ok, channel} ->
        Event.notify(:subscribed, %{socket_id: socket_id, channel: channel})
        PusherEvent.subscription_succeeded(channel)
      subscription = %PresenceSubscription{channel: channel} ->
        Event.notify(:subscribed, %{socket_id: socket_id, channel: channel})
        PusherEvent.subscription_succeeded(subscription)
      {:error, error} -> error
    end
    {:reply, {:text, reply}, req, state}
  end
  defp handle_pusher_event("pusher:unsubscribe", decoded_json, req, %State{socket_id: socket_id} = state) do
    {:ok, channel} = Subscription.unsubscribe! decoded_json["data"]
    Event.notify(:unsubscribed, %{socket_id: socket_id, channel: channel})
    {:ok, req, state}
  end
  defp handle_pusher_event("pusher:ping", _decoded_json, req, state) do
    reply = PusherEvent.pong
    {:reply, {:text, reply}, req, state}
  end
  # Client Events
  defp handle_pusher_event("client-" <> _event_name, decoded_json, req, %State{socket_id: socket_id} = state) do
    {:ok, event} = PusherEvent.build_client_event(decoded_json, socket_id)
    channel = List.first(event.channels)
    if Channel.private_or_presence?(channel) and Channel.member?(channel, self) do
      PusherEvent.publish(event)
      Event.notify(:client_event_message, %{socket_id: socket_id, channels: event.channels, name: event.name, data: event.data})
    end
    {:ok, req, state}
  end
  defp handle_pusher_event(_, _, req, state) do
    Logger.error "Undefined event"
    {:ok, req, state}
  end

  @doc """
  This function handles 3 possible cases:

  * start - Normal start after successful websocket_init
  * start_error - Improper start returning useful error code after unsuccessful websocket_init
  * msg broadcast - Any message generate by events that gets to the connection
  """
  def websocket_info(:start, req, _state) do
    # Unique identifier for the connection
    socket_id = SocketId.generate!

    SocketId.register!(socket_id)

    {origin, req} = :cowboy_req.host_url(req)
    Event.notify(:connected, %{socket_id: socket_id, origin: origin})

    reply = PusherEvent.connection_established(socket_id)
    {:reply, {:text, reply}, req, %State{socket_id: socket_id, time: Time.stamp}}
  end

  def websocket_info(:start_error, req, {code, message}) do
    {:reply, {:close, code, message}, req, nil}
  end

  def websocket_info({_pid, msg}, req, state) do
    {:reply, {:text, msg}, req, state}
  end

  def websocket_info({_pid, _msg, socket_id}, req, %State{socket_id: socket_id} = state) do
    {:ok, req, state}
  end

  def websocket_info({_pid, msg, _other_socket_id}, req, %State{socket_id: _socket_id} = state) do
    {:reply, {:text, msg}, req, state}
  end

  def websocket_info(_info, req, state), do: {:ok, req, state}

  @doc """
  Before terminating the websocket process the presence channels are checked to trigger
  member removal if necessary and explicitly unregister tags on registry
  """
  def websocket_terminate(_reason, _req, nil), do: :ok
  def websocket_terminate(_reason, _req, %State{socket_id: socket_id, time: time}) do
    duration = Time.stamp - time
    channels = Channel.all(self)
    PresenceSubscription.check_and_remove
    Poxa.registry.clean_up
    Event.notify(:disconnected, %{socket_id: socket_id, channels: channels, duration: duration})
    :ok
  end
end

defmodule Poxa.Time do
  def stamp do
    {mega, sec, _micro} = :os.timestamp()
    mega * 1000000 + sec
  end
end
