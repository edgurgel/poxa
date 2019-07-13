defmodule Poxa.PresenceSubscription do
  @moduledoc """
  This modules contains functions to treat the following events:

  * pusher:subscription_succeeded
  * pusher:subscription_error
  * pusher:member_added
  * pusher:member_removed

  More info at: http://pusher.com/docs/client_api_guide/client_presence_channels
  """
  @type user_id :: integer | binary
  @type user_info :: term
  defstruct [:channel, :channel_data]
  @type t :: %__MODULE__{channel: binary, channel_data: %{user_id => user_info}}

  alias Poxa.PusherEvent
  alias Poxa.Event
  import Poxa.Channel, only: [presence?: 1, member?: 2]
  require Logger

  @doc """
  Returns a PresenceSubscription struct
  """
  @spec subscribe!(binary, term) :: __MODULE__.t()
  def subscribe!(channel, channel_data) do
    decoded_channel_data = Jason.decode!(channel_data)

    if member?(channel, self()) do
      Logger.info("Already subscribed #{inspect(self())} on channel #{channel}")
    else
      Logger.info("Registering #{inspect(self())} to channel #{channel}")
      {user_id, user_info} = extract_userid_and_userinfo(decoded_channel_data)

      unless Poxa.Channel.member?(channel, user_id) do
        Event.notify(:member_added, %{channel: channel, user_id: user_id})
        message = PusherEvent.presence_member_added(channel, user_id, user_info)
        Poxa.registry().send!(message, channel, self())
      end

      Poxa.registry().register!(channel, {user_id, user_info})
    end

    %__MODULE__{channel: channel, channel_data: Poxa.registry().unique_subscriptions(channel)}
  end

  @spec extract_userid_and_userinfo(map) :: {user_id, user_info}
  defp extract_userid_and_userinfo(channel_data) do
    user_id = sanitize_user_id(channel_data["user_id"])
    user_info = channel_data["user_info"]
    {user_id, user_info}
  end

  defp sanitize_user_id(user_id) when is_binary(user_id), do: user_id
  defp sanitize_user_id(user_id), do: Jason.encode!(user_id)

  @doc """
  Unsubscribe from a presence channel, possibly triggering `presence_member_removed`.
  It respects multiple connections from the same user id
  """
  @spec unsubscribe!(binary) :: {:ok, binary}
  def unsubscribe!(channel) do
    case Poxa.registry().fetch(channel) do
      {user_id, _} ->
        if only_one_connection_on_user_id?(channel, user_id) do
          presence_member_removed(channel, user_id)
        end

      _ ->
        nil
    end

    {:ok, channel}
  end

  @doc """
  This function checks if the user that is leaving the presence channel
  has more than one connection subscribed.

  If the connection is the only one, fire up the member_removed event
  """
  @spec check_and_remove :: non_neg_integer
  def check_and_remove do
    for [channel, user_id] <- Poxa.registry().subscriptions(self()),
        presence?(channel),
        only_one_connection_on_user_id?(channel, user_id) do
      presence_member_removed(channel, user_id)
    end
    |> Enum.count()
  end

  defp presence_member_removed(channel, user_id) do
    Event.notify(:member_removed, %{channel: channel, user_id: user_id})
    message = PusherEvent.presence_member_removed(channel, user_id)
    Poxa.registry().send!(message, channel, self())
  end

  defp only_one_connection_on_user_id?(channel, user_id) do
    Poxa.registry().subscription_count(channel, user_id) == 1
  end
end
