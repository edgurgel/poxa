defmodule Poxa.WebsocketHandler do
  @moduledoc """
  This module contains Cowboy Websocket handler callbacks to requests on /apps/:app_key

  More info on Cowboy HTTP handler at: http://ninenines.eu/docs/en/cowboy/HEAD/guide/ws_handlers

  More info on Pusher protocol at: http://pusher.com/docs/pusher_protocol
  """
  require Lager
  alias Poxa.PusherEvent
  alias Poxa.PresenceSubscription
  alias Poxa.Subscription

  def init(_transport, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  def websocket_init(_transport_name, req, _opts) do
    {app_key, req} = :cowboy_req.binding(:app_key, req)
    case :application.get_env(:poxa, :app_key) do
      {:ok, ^app_key} ->
        self <- :start
        {:ok, req, nil}
      _ ->
        Lager.error('Invalid app_key, expected ~p, found ~p',
          [:application.get_env(:poxa, :app_key), app_key])
        {:shutdown, req}
    end
  end

  def websocket_handle({:text, json}, req, state) do
    JSEX.decode!(json)
      |> handle_pusher_event(req, state)
  end

  def handle_pusher_event(decoded_json, req, state) do
    handle_pusher_event(decoded_json["event"], decoded_json, req, state)
  end

  defp handle_pusher_event("pusher:subscribe", decoded_json, req, state) do
    data = decoded_json["data"]
    reply = case Subscription.subscribe!(data, state) do
      :ok -> PusherEvent.subscription_succeeded
      {:presence, channel, presence_data} -> PusherEvent.presence_subscription_succeeded(channel, presence_data)
      :error -> PusherEvent.subscription_error
    end
    {:reply, {:text, reply}, req, state}
  end
  defp handle_pusher_event("pusher:unsubscribe", decoded_json, req, state) do
    :ok = Subscription.unsubscribe! decoded_json["data"]
    {:ok, req, state}
  end
  defp handle_pusher_event("pusher:ping", _decoded_json, req, state) do
    reply = PusherEvent.pong
    {:reply, {:text, reply}, req, state}
  end
  # Client Events
  defp handle_pusher_event("client-" <> _event_name = _event, decoded_json, req, state) do
    {message, channels, _exclude} = PusherEvent.parse_channels(decoded_json)
    lc channel inlist channels, private_or_presence_channel(channel), Subscription.subscribed?(channel) do
      PusherEvent.send_message_to_channel(channel, message, [self])
    end
    {:ok, req, state}
  end
  defp handle_pusher_event(_, _data, req, state) do
    Lager.info("Undefined event")
    {:ok, req, state}
  end

  defp private_or_presence_channel(channel) do
    case channel do
      "presence-" <> _presence_channel -> true
      "private-" <> _private_channel -> true
      _ -> false
    end
  end

  def websocket_info(:start, req, _State) do
    # Unique identifier for the connection
    socket_id = generate_uuid
    # Register the name of the connection as SocketId
    :gproc.reg({:n, :l, socket_id})
    reply = PusherEvent.connection_established(socket_id)
    {:reply, {:text, reply}, req, socket_id}
  end

  def websocket_info({_pid, msg}, req, state) do
    {:reply, {:text, msg}, req, state}
  end

  def websocket_info(info, req, state) do
    {:ok, req, state}
  end

  defp generate_uuid do
    :uuid.uuid1
    |> :uuid.to_string
    |> list_to_binary
  end

  def websocket_terminate(_reason, _req, _state) do
    PresenceSubscription.check_and_remove
    :gproc.goodbye
    :ok
  end
end
