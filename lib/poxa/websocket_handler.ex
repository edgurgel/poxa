defmodule Poxa.WebsocketHandler do
  @behaviour :cowboy_websocket_handler
  @moduledoc """
  This module contains Cowboy Websocket handler callbacks to requests on /apps/:app_key

  More info on Cowboy HTTP handler at: http://ninenines.eu/docs/en/cowboy/HEAD/guide/ws_handlers

  More info on Pusher protocol at: http://pusher.com/docs/pusher_protocol
  """
  require Lager
  alias Poxa.PusherEvent
  alias Poxa.Console
  alias Poxa.PresenceSubscription
  alias Poxa.Subscription

  @max_protocol 7
  @min_protocol 5

  def init(_transport, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  def websocket_init(_transport_name, req, _opts) do
    {app_key, req} = :cowboy_req.binding(:app_key, req)
    {protocol, req} = :cowboy_req.qs_val("protocol", req, to_string(@max_protocol))
    case :application.get_env(:poxa, :app_key) do
      {:ok, ^app_key} ->
        if supported_protocol?(protocol) do
          send self, :start
          {:ok, req, nil}
        else
          Lager.error "Protocol #{protocol} not supported"
          send self, :start_error
          {:ok, req, {4007, "Unsupported protocol version"}}
        end
      {:ok, expected_app_key} ->
        Lager.error "Invalid app_key, expected #{expected_app_key}, found #{app_key}"
          send self, :start_error
          {:ok, req, {4001, "Application does not exist"}}
    end
  end

  defp supported_protocol?(protocol) do
    try do
      protocol = binary_to_integer(protocol)
      if protocol>= @min_protocol && protocol <= @max_protocol, do: true,
      else: false
    rescue
      ArgumentError -> false
    end
  end

  def websocket_handle({:text, json}, req, socket_id) do
    JSEX.decode!(json) |> handle_pusher_event(req, socket_id)
  end

  def handle_pusher_event(decoded_json, req, socket_id) do
    handle_pusher_event(decoded_json["event"], decoded_json, req, socket_id)
  end

  defp handle_pusher_event("pusher:subscribe", decoded_json, req, socket_id) do
    data = decoded_json["data"]
    reply = case Subscription.subscribe!(data, socket_id) do
      {:ok, channel} ->
        Console.subscribed(socket_id, channel)
        PusherEvent.subscription_succeeded(channel)
      {:presence, channel, presence_data} ->
        Console.subscribed(socket_id, channel)
        PusherEvent.presence_subscription_succeeded(channel, presence_data)
      :error -> PusherEvent.subscription_error
    end
    {:reply, {:text, reply}, req, socket_id}
  end
  defp handle_pusher_event("pusher:unsubscribe", decoded_json, req, socket_id) do
    {:ok, channel} = Subscription.unsubscribe! decoded_json["data"]
    Console.unsubscribed(socket_id, channel)
    {:ok, req, socket_id}
  end
  defp handle_pusher_event("pusher:ping", _decoded_json, req, socket_id) do
    reply = PusherEvent.pong
    {:reply, {:text, reply}, req, socket_id}
  end
  # Client Events
  defp handle_pusher_event("client-" <> _event_name, decoded_json, req, socket_id) do
    {message, channels, _exclude} = PusherEvent.parse_channels(decoded_json)
    sent_channels = lc channel inlist channels, private_or_presence_channel(channel), Subscription.subscribed?(channel) do
      PusherEvent.send_message_to_channel(channel, message, [self])
      channel
    end
    unless Enum.empty?(sent_channels) do
      Console.client_event_message(socket_id, sent_channels, message)
    end
    {:ok, req, socket_id}
  end
  defp handle_pusher_event(_, _data, req, socket_id) do
    Lager.error "Undefined event"
    {:ok, req, socket_id}
  end

  defp private_or_presence_channel(channel) do
    case channel do
      "presence-" <> _presence_channel -> true
      "private-" <> _private_channel -> true
      _ -> false
    end
  end

  def websocket_info(:start, req, _state) do
    # Unique identifier for the connection
    socket_id = generate_uuid
    # Register the name of the connection as SocketId
    :gproc.reg({:n, :l, socket_id})

    {origin, req} = :cowboy_req.host_url(req)
    Console.connected(socket_id, origin)

    reply = PusherEvent.connection_established(socket_id)
    {:reply, {:text, reply}, req, socket_id}
  end

  def websocket_info(:start_error, req, {code, message}) do
    {:reply, {:close, code, message}, req, nil}
  end

  def websocket_info({_pid, msg}, req, socket_id) do
    {:reply, {:text, msg}, req, socket_id}
  end

  def websocket_info(_info, req, socket_id) do
    {:ok, req, socket_id}
  end

  defp generate_uuid do
    :uuid.uuid1
    |> :uuid.to_string
    |> String.from_char_list!
  end

  def websocket_terminate(_reason, _req, nil), do: :ok
  def websocket_terminate(_reason, _req, socket_id) do
    channels = Subscription.channels(self)
    Console.disconnected(socket_id, channels)
    PresenceSubscription.check_and_remove
    :gproc.goodbye
    :ok
  end
end
