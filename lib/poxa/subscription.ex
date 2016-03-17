defmodule Poxa.Subscription do
  @moduledoc """
  This module contains functions to handle subscription and unsubscription
  on channels, public, private and presence channels.
  """
  alias Poxa.AuthSignature
  alias Poxa.PresenceSubscription
  alias Poxa.Channel
  alias Poxa.PusherEvent
  require Logger

  @doc """
  Subscribe to a channel on this process.
  Returns {:ok, channel} to public and private channels and
  a PresenceSubscription to a presence channel
  """
  @spec subscribe!(:jsx.json_term, binary) :: {:ok, binary}
    | PresenceSubscription.t
    | {:error, binary}
  def subscribe!(data, socket_id) do
    channel = data["channel"]
    cond do
      Channel.private?(channel) ->
        subscribe_private_channel(socket_id, channel, data["auth"], data["channel_data"])
      Channel.presence?(channel) ->
        subscribe_presence_channel(socket_id, channel, data["auth"], data["channel_data"])
      is_binary(channel) ->
        subscribe_channel(channel)
      true ->
        Logger.info "Missing channel"
        {:error, PusherEvent.pusher_error("Missing parameter: data.channel")}
    end
  end

  defp subscribe_presence_channel(socket_id, channel, auth, channel_data) do
    to_sign = socket_id <> ":" <> channel <> ":" <> (channel_data || "")
    if AuthSignature.valid?(to_sign, auth) do
      PresenceSubscription.subscribe!(channel, channel_data)
    else
      {:error, signature_error(to_sign, auth)}
    end
  end

  defp subscribe_private_channel(socket_id, channel, auth, channel_data) do
    to_sign = case channel_data do
      nil -> socket_id <> ":" <> channel
      channel_data -> socket_id <> ":" <> channel <> ":" <> channel_data
    end
    if AuthSignature.valid?(to_sign, auth) do
      subscribe_channel(channel)
    else
      {:error, signature_error(to_sign, auth)}
    end
  end

  defp signature_error(to_sign, auth) do
    msg = "Invalid signature: Expected HMAC SHA256 hex digest of #{to_sign}, but got #{auth}"
    PusherEvent.pusher_error(msg)
  end

  defp subscribe_channel(channel) do
    Logger.info "Subscribing to channel #{channel}"
    if Channel.member?(channel, self) do
      Logger.info "Already subscribed #{inspect self} on channel #{channel}"
    else
      Logger.info "Registering #{inspect self} to channel #{channel}"
      Poxa.registry.register!(channel)
    end
    {:ok, channel}
  end

  @doc """
  Unsubscribe from a channel always returning :ok
  """
  @spec unsubscribe!(:jsx.json_term) :: {:ok, binary}
  def unsubscribe!(data) do
    channel = data["channel"]
    if Channel.member?(channel, self) do
      if Channel.presence?(channel) do
        PresenceSubscription.unsubscribe!(channel);
      end
      Poxa.registry.unregister!(channel)
    else
      Logger.debug "Not subscribed to"
    end
    {:ok, channel}
  end
end
