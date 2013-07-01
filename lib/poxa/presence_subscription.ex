defmodule Poxa.PresenceSubscription do
  @moduledoc """
  This modules contains functions to treat the following events:

  * pusher:subscription_succeeded
  * pusher:subscription_error
  * pusher:member_added
  * pusher:member_removed

  More info at: http://pusher.com/docs/client_api_guide/client_presence_channels
  """
  @type user_id :: integer | binary # Maybe a json_term too?

  alias Poxa.PusherEvent
  alias Poxa.Subscription
  require Lager

  @doc """
  Returns {:presence, `channel`, [{pid(), {user_id, user_info}}]
  """
  @spec subscribe!(binary, :jsx.json_term) :: {:presence, binary, [{pid, {user_id, :jsx.json_term}}]}
  def subscribe!(channel, channel_data) do
    decoded_channel_data = JSEX.decode!(channel_data)
    if Subscription.subscribed?(channel) do
      Lager.info('Already subscribed ~p on channel ~p', [self, channel])
    else
      Lager.info('Registering ~p to channel ~p', [self, channel])
      {user_id, user_info} = extract_userid_and_userinfo(decoded_channel_data)
      if user_id_already_on_presence_channel(user_id, channel) do
        :gproc.update_shared_counter({:c, :l, {:presence, channel, user_id}}, 1)
      else
        message = PusherEvent.presence_member_added(channel, user_id, user_info)
        :gproc.add_shared_local_counter({:presence, channel, user_id}, 1)
        :gproc.send({:p, :l, {:pusher, channel}}, {self, message})
      end
      :gproc.reg({:p, :l, {:pusher, channel}}, {user_id, user_info})
    end
    {:presence, channel, :gproc.lookup_values({:p, :l, {:pusher, channel}})}
  end

  defp extract_userid_and_userinfo(channel_data) do
    user_id = sanitize_user_id(ListDict.get(channel_data, "user_id"))
    user_info = ListDict.get(channel_data, "user_info")
    {user_id, user_info}
  end

  @spec unsubscribe!(binary) :: :ok
  def unsubscribe!(channel) do
    case :gproc.get_value({:p, :l, {:pusher, channel}}) do
      {user_id, _} ->
        message = PusherEvent.presence_member_removed(channel, user_id)
        :gproc.send({:p, :l, {:pusher, channel}}, {self, message})
      _ -> nil
    end
    :ok
  end

  @doc """
  This function returns the user ids currently subscribed to a presence channel

  More info at: http://pusher.com/docs/rest_api#method-get-users
  """
  @spec users(binary) :: [user_id]
  def users(channel) do
    match = {{:p, :l, {:pusher, channel}}, :_, :'$1'}
    :gproc.select([{match, [], [:'$1']}])
    |> Enum.uniq(fn {user_id, _} -> user_id end)
    |> Enum.map(fn {user_id, _} -> user_id end)
  end

  @doc """
  This function checks if the user that is leaving the presence channel
  have more than one connection subscribed.

  If the connection is unique, fire up the member_removed event
  Otherwise decrement the counter
  """
  @spec check_and_remove :: :ok
  def check_and_remove do
    match = {{:p, :l, {:pusher, :'$1'}}, self, {:'$2', :_}}
    channel_user_id = :gproc.select([{match, [], [[:'$1',:'$2']]}])
    member_remove_fun = fn([channel, user_id]) ->
      if presence_channel?(channel) do
        if only_one_connection_on_user_id?(channel, user_id) do
          :gproc.unreg_shared({:c, :l, {:presence, channel, user_id}})
          message = PusherEvent.presence_member_removed(channel, user_id)
          :gproc.send({:p, :l, {:pusher, channel}}, {self, message})
        else
          :gproc.update_shared_counter({:c, :l, {:presence, channel, user_id}}, -1)
        end
      end
    end
    Enum.each(channel_user_id, member_remove_fun)
    :ok
  end

  @spec presence_channel?(any) :: boolean
  def presence_channel?("presence-" <> _presence_channel  = _channel) do
    true
  end
  def presence_channel?(_), do: false

  defp sanitize_user_id(user_id) do
    case JSEX.is_term?(user_id) do
      true -> JSEX.encode!(user_id)
      false -> user_id
    end
  end

  defp user_id_already_on_presence_channel(user_id, channel) do
    match = {{:p, :l, {:pusher, channel}}, :_, {user_id, :_}}
    case :gproc.select([{match, [], [:'$$']}]) do
      [] -> false
      _ -> true
    end
  end

  defp only_one_connection_on_user_id?(channel, user_id) do
    case :gproc.get_value({:c, :l, {:presence, channel, user_id}}, :shared) do
      1 -> true
      _ -> false
    end
  end
end
