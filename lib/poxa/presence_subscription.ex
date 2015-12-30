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
  @type user_info :: :jsx.json_term
  defstruct [:channel, :channel_data]
  @type t :: %__MODULE__{channel: binary, channel_data: [{user_id, user_info}]}

  alias Poxa.PusherEvent
  import Poxa.Channel, only: [presence?: 1, subscribed?: 3]
  require Logger

  @doc """
  Returns a PresenceSubscription struct
  """
  @spec subscribe!(binary, binary, :jsx.json_term) :: __MODULE__.t
  def subscribe!(app_id, channel, channel_data) do
    decoded_channel_data = JSX.decode!(channel_data)
    if subscribed?(app_id, channel, self) do
      Logger.info "Already subscribed #{inspect self} on channel #{channel}"
    else
      Logger.info "Registering #{inspect self} to channel #{channel}"
      {user_id, user_info} = extract_userid_and_userinfo(decoded_channel_data)
      unless user_id_already_on_presence_channel(app_id, user_id, channel) do
        message = PusherEvent.presence_member_added(channel, user_id, user_info)
        :gproc.send({:p, :l, {:pusher, app_id, channel}}, {self, message})
      end
      :gproc.reg({:p, :l, {:pusher, app_id, channel}}, {user_id, user_info})
    end
    %__MODULE__{channel: channel, channel_data: channel_data(app_id, channel)}
  end

  defp channel_data(app_id, channel) do
    for {_pid, {user_id, user_info}} <- :gproc.lookup_values({:p, :l, {:pusher, app_id, channel}}) do
      {user_id, user_info}
    end |> Enum.uniq(fn {user_id, _} -> user_id end)
  end

  defp extract_userid_and_userinfo(channel_data) do
    user_id = sanitize_user_id(channel_data["user_id"])
    user_info = channel_data["user_info"]
    {user_id, user_info}
  end

  defp sanitize_user_id(user_id) when is_binary(user_id), do: user_id
  defp sanitize_user_id(user_id), do: JSX.encode!(user_id)

  defp user_id_already_on_presence_channel(app_id, user_id, channel) do
    match = {{:p, :l, {:pusher, app_id, channel}}, :_, {user_id, :_}}
    :gproc.select_count([{match, [], [true]}]) != 0
  end

  @doc """
  Unsubscribe from a presence channel, possibly triggering presence_member_removed
  It respects multiple connections from the same user id
  """
  @spec unsubscribe!(binary, binary) :: {:ok, binary}
  def unsubscribe!(app_id, channel) do
    case :gproc.get_value({:p, :l, {:pusher, app_id, channel}}) do
      {user_id, _} ->
        if only_one_connection_on_user_id?(app_id, channel, user_id) do
          presence_member_removed(app_id, channel, user_id)
        end
      _ -> nil
    end
    {:ok, channel}
  end

  @doc """
  This function checks if the user that is leaving the presence channel
  has more than one connection subscribed.

  If the connection is the only one, fire up the member_removed event
  """
  @spec check_and_remove(binary) :: :ok
  def check_and_remove(app_id) do
    match = {{:p, :l, {:pusher, app_id, :'$1'}}, self, {:'$2', :_}}
    channel_user_id = :gproc.select([{match, [], [[:'$1',:'$2']]}])
    for [channel, user_id] <- channel_user_id,
      presence?(channel), only_one_connection_on_user_id?(app_id, channel, user_id) do
        presence_member_removed(app_id, channel, user_id)
    end
    :ok
  end

  defp presence_member_removed(app_id, channel, user_id) do
    message = PusherEvent.presence_member_removed(channel, user_id)
    :gproc.send({:p, :l, {:pusher, app_id, channel}}, {self, message})
  end

  defp only_one_connection_on_user_id?(app_id, channel, user_id) do
    match = {{:p, :l, {:pusher, app_id, channel}}, :_, {user_id, :_}}
    :gproc.select_count([{match, [], [true]}]) == 1
  end
end
