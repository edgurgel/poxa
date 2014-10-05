defmodule Poxa.Subscription do
  @moduledoc """
  This module contains functions to handle subscription and unsubscription
  on channels, public, private and presence channels.
  """
  alias Poxa.AuthSignature
  alias Poxa.PresenceSubscription
  alias Poxa.Channel
  require Logger

  @doc """
  Subscribe to a channel on this process.
  Returns {:ok, channel} to public and private channels and
  a PresenceSubscription to a presence channel
  """
  @spec subscribe!(:jsx.json_term, binary) :: {:ok, binary}
    | {:presence, binary, {PresenceSubscription.user_id, :jsx.json_term}}
    | :error
  def subscribe!(data, socket_id) do
    channel = data["channel"]
    cond do
      Channel.private?(channel) ->
        to_sign = case data["channel_data"] do
          nil -> socket_id <> ":" <> channel
          channel_data -> socket_id <> ":" <> channel <> ":" <> channel_data
        end
        case AuthSignature.validate(to_sign, data["auth"]) do
          :ok -> subscribe_channel(channel)
          :error -> subscribe_error(channel)
        end
      Channel.presence?(channel) ->
        channel_data = Dict.get(data, "channel_data", "undefined")
        to_sign = socket_id <> ":" <> channel <> ":" <> channel_data
        case AuthSignature.validate(to_sign, data["auth"]) do
          :ok -> PresenceSubscription.subscribe!(channel, channel_data)
          :error -> subscribe_error(channel)
        end
      is_binary(channel) ->
        subscribe_channel(channel)
      true ->
        Logger.info "Missing channel"
        :error
    end
  end

  defp subscribe_error(channel) do
    Logger.info "Error while subscribing to channel #{channel}"
    :error
  end

  defp subscribe_channel(channel) do
    Logger.info "Subscribing to channel #{channel}"
    if Channel.subscribed?(channel, self) do
      Logger.info "Already subscribed #{inspect self} on channel #{channel}"
    else
      Logger.info "Registering #{inspect self} to channel #{channel}"
      :gproc.reg({:p, :l, {:pusher, channel}})
    end
    {:ok, channel}
  end

  @doc """
  Unsubscribe from a channel always returning :ok
  """
  @spec unsubscribe!(:jsx.json_term) :: {:ok, binary}
  def unsubscribe!(data) do
    channel = data["channel"]
    if Channel.presence?(channel) do
      PresenceSubscription.unsubscribe!(channel);
    end
    unsubscribe_channel(channel)
  end

  defp unsubscribe_channel(channel) do
    Logger.info "Unsubscribing to channel #{channel}"
    case Channel.subscribed?(channel, self) do
      true -> :gproc.unreg({:p, :l, {:pusher, channel}});
      false -> Logger.debug "Already subscribed"
    end
    {:ok, channel}
  end
end
