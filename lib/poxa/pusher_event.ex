defmodule Poxa.PusherEvent do
  @moduledoc """
  This module contains a set of functions to work with pusher events

  Take a look at http://pusher.com/docs/pusher_protocol#events for more info
  """
  require Lager

  @doc """
  Return a JSON for an established connection using the `socket_id` parameter to
  identify this connection

      { "event" : "pusher:connection_established",
        "data" : { "socket_id" : "129319" } }"
  """
  def connection_established(socket_id) do
    :jsx.encode([ event: "pusher:connection_established",
                   data: [ socket_id: socket_id ] ])
  end

  @subscription_succeeded :jsx.encode([ event: "pusher_internal:subscription_succeeded",
                                        data: [] ])
  @doc """
  Return a JSON for a succeeded subscription

      "{ "event" : "pusher_internal:subscription_succeeded",
         "data" : [] }"
  """
  def subscription_succeeded do
    @subscription_succeeded
  end

  @subscription_error :jsx.encode([ event: "pusher:subscription_error",
                                    data: [] ])
  @doc """
  Return a JSON for a subscription error

      "{ "event" : "pusher:subscription_error",
         "data" : [] }"
  """
  def subscription_error do
    @subscription_error
  end

  @pong :jsx.encode([ event: "pusher:pong",
                      data: [] ])
  @doc """
  PING? PONG!

      "{ "event" : "pusher:pong",
         "data" : [] }"
  """
  def pong do
    @pong
  end

  @doc """
  Returns a JSON for a succeeded presence subscription

      { "event": "pusher_internal:subscription_succeeded",
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
      }
  """
  def presence_subscription_succeeded(channel, presence_data) do
    # This may be too slow in the future...let's wait and see :)
    ids_hash = lc {_pid, {user_id, user_info}} inlist presence_data do
      {user_id, user_info}
    end
    [ids, _Hash] = List.unzip(ids_hash)
    count = Enum.count(ids)
    :jsx.encode([ event: "pusher_internal:subscription_succeeded",
                  channel: channel,
                  data: [ presence: [ ids: ids,
                                      hash: ids_hash,
                                      count: count ]
                        ]
               ])
  end

  @doc """
  Returns a JSON for a new member subscription on a presence channel

      "{ "event" : "pusher_internal:member_added",
         "channel" : "public-channel",
         "data" : { "user_id" : 123,
                    "user_info" : "456" } }"
  """
  def presence_member_added(channel, user_id, user_info) do
    :jsx.encode([ event: "pusher_internal:member_added",
                  channel: channel,
                  data: [ user_id: user_id,
                          user_info: user_info]
                ])
  end

  @doc """
  Returns a JSON for a member having the id `user_id` unsubscribing on
  a presence channel named `channel`

      "{ "event" : "pusher_internal:member_added",
         "channel" : "public-channel",
         "data" : { "user_id" : 123 } }"
  """
  def presence_member_removed(channel, user_id) do
    :jsx.encode([ event: "pusher_internal:member_removed",
                  channel: channel,
                  data: [ user_id: user_id]
                ])
  end

  @doc """
  Returns a list of channels, the message without the channel info and
  possibly a socket_id to exclude.

  ## Examples
      iex> Poxa.PusherEvent.parse_channels([{"channel", "private-channel"}])
      {[],["private-channel"],:undefined}
      iex> Poxa.PusherEvent.parse_channels([{"channels", ["private-channel", "public-channel"]}])
      {[],["private-channel","public-channel"],:undefined}
      iex> Poxa.PusherEvent.parse_channels([{"channel", "a-channel"}, {"socket_id", "to_exclude123" }])
      {[{"socket_id","to_exclude123"}],["a-channel"],"to_exclude123"}

  """
  def parse_channels(message) do
    exclude = :proplists.get_value("socket_id", message, :undefined)
    case :proplists.get_value("channel", message) do
      :undefined ->
        case :proplists.get_value("channels", message) do
          :undefined -> {message, :undefined, exclude} # channel/channels not found
          channels ->
            message = :proplists.delete("channels", message)
            {message, channels, exclude}
        end
      channel ->
        message = :proplists.delete("channel", message)
        {message, [channel], exclude}
    end
  end

  @doc """
  Send `message` to `channels` excluding `exclude`
  """
  def send_message_to_channels(channels, message, exclude) do
    Lager.debug("Sending message to channels ~p", [channels])
    pid_to_exclude = case exclude do
      :undefined -> []
      _ -> :gproc.lookup_pids({:n, :l, exclude})
    end
    lc channel inlist channels do
      send_message_to_channel(channel, message, pid_to_exclude)
    end
  end


  @doc """
  Send `message` to `channel` excluding `exclude` appending the channel name info
  to the message
  """
  def send_message_to_channel(channel, message, pid_to_exclude) do
    message = :lists.append(message, [{"channel", channel}])
    pids = :gproc.lookup_pids({:p, :l, {:pusher, channel}})
    pids = pids -- pid_to_exclude

    lc pid inlist pids do
      pid <- {self, :jsx.encode(message)}
    end
  end

end
