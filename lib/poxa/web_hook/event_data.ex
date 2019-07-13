defmodule Poxa.WebHook.EventData do
  @moduledoc """
  This module contains a set of functions to generate web hook events.

  Take a look at https://pusher.com/docs/webhooks#events for more details.
  """

  alias Poxa.PresenceSubscription

  @doc """
  Returns a map describing the event happening whenever any channel becomes occupied (i.e. there is at least one subscriber).

  ## Example

      iex> Poxa.WebHook.EventData.channel_occupied("test_channel")
      %{name: "channel_occupied", channel: "test_channel"}
  """
  @spec channel_occupied(binary) :: map
  def channel_occupied(channel) do
    %{name: "channel_occupied", channel: channel}
  end

  @doc """
  Returns a map describing the event happening whenever any channel becomes vacated (i.e. there is no subscriber).

  ## Example

      iex> Poxa.WebHook.EventData.channel_vacated("test_channel")
      %{name: "channel_vacated", channel: "test_channel"}
  """
  @spec channel_vacated(binary) :: map
  def channel_vacated(channel) do
    %{name: "channel_vacated", channel: channel}
  end

  @doc """
  Returns a map describing the event happening whenever a new user subscribes to a presence channel.

  ## Example

      iex> Poxa.WebHook.EventData.member_added("presence-test_channel", "test_user_id")
      %{name: "member_added", channel: "presence-test_channel", user_id: "test_user_id"}
  """
  @spec member_added(binary, PresenceSubscription.user_id()) :: map
  def member_added(channel, user_id) do
    %{name: "member_added", channel: channel, user_id: user_id}
  end

  @doc """
  Returns a map describing the event happening whenever a new user unsubscribes from a presence channel.

  ## Example

      iex> Poxa.WebHook.EventData.member_removed("presence-test_channel", "test_user_id")
      %{name: "member_removed", channel: "presence-test_channel", user_id: "test_user_id"}
  """
  @spec member_removed(binary, PresenceSubscription.user_id()) :: map
  def member_removed(channel, user_id) do
    %{name: "member_removed", channel: channel, user_id: user_id}
  end

  @doc """
  Returns a map describing the event happening whenever a client event is sent on any channel.

  ## Examples

      iex> Poxa.WebHook.EventData.client_event("test_channel", "event name", "associated data", "test_socket_id", "test_user_id")
      %{
        name: "client_event",
        channel: "test_channel",
        event: "event name",
        data: "associated data",
        socket_id: "test_socket_id",
        user_id: "test_user_id"
      }

      iex> Poxa.WebHook.EventData.client_event("test_channel", "event name", %{associated: "data"}, "test_socket_id", nil)
      %{
        name: "client_event",
        channel: "test_channel",
        event: "event name",
        data: %{associated: "data"},
        socket_id: "test_socket_id",
      }
  """
  @spec client_event(binary, binary, any, binary, PresenceSubscription.user_id() | nil) :: map
  def client_event(channel, event, data, socket_id, nil) do
    Map.delete(client_event(channel, event, data, socket_id, ""), :user_id)
  end

  def client_event(channel, event, data, socket_id, user_id) do
    %{
      name: "client_event",
      channel: channel,
      event: event,
      data: data,
      socket_id: socket_id,
      user_id: user_id
    }
  end
end
