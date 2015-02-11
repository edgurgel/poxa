defmodule Poxa.PusherEvent do
  @moduledoc """
  This module contains a set of functions to work with pusher events

  Take a look at http://pusher.com/docs/pusher_protocol#events for more info
  """

  alias Poxa.PresenceSubscription
  import JSX, only: [encode!: 1]

  @doc """
  Return a JSON for an established connection using the `socket_id` parameter to
  identify this connection

      { "event" : "pusher:connection_established",
        "data" : {
          "socket_id" : "129319",
          "activity_timeout" : 12
        }
      }"
  """
  @spec connection_established(binary) :: binary
  def connection_established(socket_id) do
    data = %{socket_id: socket_id, activity_timeout: 120} |> encode!
    %{event: "pusher:connection_established",
      data: data} |> encode!
  end

  @doc """
  Return a JSON for a succeeded subscription

      "{ "event" : "pusher_internal:subscription_succeeded",
         "channel" : "public-channel",
         "data" : {} }"

  If it's a presence subscription the following JSON is generated

      "{ "event": "pusher_internal:subscription_succeeded",
        "channel": "presence-example-channel",
        "data": {
          "presence": {
          "ids": ["1234","98765"],
          "hash": {
            "1234": {
              "name":"John Locke",
              "twitter": "@jlocke"
            },
            "98765": {
              "name":"Nicola Tesla",
              "twitter": "@ntesla"
            }
          },
          "count": 2
          }
        }
      }"
  """
  @spec subscription_succeeded(binary | PresenceSubscription.t) :: binary
  def subscription_succeeded(channel) when is_binary(channel) do
    %{event: "pusher_internal:subscription_succeeded",
      channel: channel,
      data: %{} } |> encode!
  end

  def subscription_succeeded(%PresenceSubscription{channel: channel, channel_data: channel_data}) do
    {ids, _Hash} = :lists.unzip(channel_data)
    count = Enum.count(ids)
    data = %{presence: %{ids: ids, hash: channel_data, count: count}} |> encode!
    %{event: "pusher_internal:subscription_succeeded",
      channel: channel,
      data: data } |> encode!
  end

  @subscription_error %{event: "pusher:subscription_error", data: %{}} |> encode!
  @doc """
  Return a JSON for a subscription error

      "{ "event" : "pusher:subscription_error",
         "data" : {} }"
  """
  @spec subscription_error :: <<_ :: 376>>
  def subscription_error, do: @subscription_error

  @pong %{event: "pusher:pong", data: %{}} |> encode!
  @doc """
  PING? PONG!

      "{ "event" : "pusher:pong",
         "data" : {} }"
  """
  @spec pong :: <<_ :: 264>>
  def pong, do: @pong

  @doc """
  Returns a JSON for a new member subscription on a presence channel

      "{ "event" : "pusher_internal:member_added",
         "channel" : "public-channel",
         "data" : { "user_id" : 123,
                    "user_info" : "456" } }"
  """
  @spec presence_member_added(binary, PresenceSubscription.user_id, PresenceSubscription.user_info) :: binary
  def presence_member_added(channel, user_id, user_info) do
    data = %{user_id: user_id, user_info: user_info} |> encode!
    %{event: "pusher_internal:member_added",
      channel: channel,
      data: data} |> encode!
  end

  @doc """
  Returns a JSON for a member having the id `user_id` unsubscribing on
  a presence channel named `channel`

      "{ "event" : "pusher_internal:member_removed",
         "channel" : "public-channel",
         "data" : { "user_id" : 123 } }"
  """
  @spec presence_member_removed(binary, PresenceSubscription.user_id) :: binary
  def presence_member_removed(channel, user_id) do
    data = %{user_id: user_id} |> encode!
    %{event: "pusher_internal:member_removed",
      channel: channel,
      data: data} |> encode!
  end

  @doc """
  Returns a list of channels, the message without the channel info and
  possibly a socket_id to exclude.

  ## Examples
      iex> Poxa.PusherEvent.parse_channels(%{"channel" => "private-channel"})
      {%{}, ["private-channel"],nil}
      iex> Poxa.PusherEvent.parse_channels(%{"channels" => ["private-channel", "public-channel"]})
      {%{}, ["private-channel","public-channel"],nil}
      iex> Poxa.PusherEvent.parse_channels(%{"channel" => "a-channel", "socket_id" => "to_exclude123" })
      {%{"socket_id" => "to_exclude123"},["a-channel"],"to_exclude123"}

  """
  @spec parse_channels(map) :: {:jsx.json_term,
                                [binary] | :undefined,
                                :undefined | binary}
  def parse_channels(message) do
    exclude = message["socket_id"]
    case Dict.pop(message, "channels") do
      {nil, message} ->
        case Dict.pop(message, "channel") do
          {nil, message} -> {message, nil, exclude}
          {channel, message} -> {message, [channel], exclude}
        end
      {channels, message} ->{message, channels, exclude}
    end
  end

  defstruct [:channels, :name, :data, :socket_id]
  @type t :: %Poxa.PusherEvent{channels: list, name: binary,
                               data: binary | map, socket_id: nil | binary}

  @doc """
  Builds the struct based on the decoded JSON from /events endpoint
  """
  @spec build(map) :: Poxa.PusherEvent.t
  def build(%{"name" => name, "channels" => channels, "data" => data} = event) do
    %Poxa.PusherEvent{channels: channels, data: data, name: name, socket_id: event["socket_id"]}
  end
  def build(%{"name" => name, "channel" => channel, "data" => data} = event) do
    %Poxa.PusherEvent{channels: [channel], data: data, name: name, socket_id: event["socket_id"]}
  end

  def build_client_event(%{"event" => event, "channel" => channel, "data" => data}, socket_id) do
    %Poxa.PusherEvent{channels: [channel], data: data, name: event, socket_id: socket_id}
  end
  def build_client_event(%{"name" => event, "channel" => channel, "data" => data}, socket_id) do
    %Poxa.PusherEvent{channels: [channel], data: data, name: event, socket_id: socket_id}
  end

  @doc """
  Send `message` to `channels` excluding `exclude`
  """
  @spec publish(Poxa.PusherEvent.t) :: :ok
  def publish(%Poxa.PusherEvent{channels: channels, socket_id: exclude} = event) do
    exclude = event.socket_id
    pid_to_exclude = if exclude, do: :gproc.lookup_pids({:n, :l, exclude}),
    else: []
    for channel <- channels do
      publish_event_to_channel(event, channel, pid_to_exclude)
    end
    :ok
  end

  @doc """
  Send `message` to `channel` excluding `exclude` appending the channel name info
  to the message
  """
  @spec publish_event_to_channel(Poxa.PusherEvent.t, binary, [pid]) :: :ok
  def publish_event_to_channel(event, channel, pid_to_exclude) do
    message = build_message(event, channel) |> encode!
    pids = :gproc.lookup_pids({:p, :l, {:pusher, channel}})
    pids = pids -- pid_to_exclude

    for pid <- pids do
      send pid, {self, message}
    end
    :ok
  end

  defp build_message(event, channel) do
    %{event: event.name, data: event.data, channel: channel}
  end
end
