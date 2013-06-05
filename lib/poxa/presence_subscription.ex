defmodule Poxa.PresenceSubscription do
  @moduledoc """
  This modules contains functions to treat the following events:

  * pusher:subscription_succeeded
  * pusher:subscription_error
  * pusher:member_added
  * pusher:member_removed

  More info at: http://pusher.com/docs/client_api_guide/client_presence_channels
  """
  alias Poxa.PusherEvent
  alias Poxa.Subscription
  require Lager

  @doc """
  Returns {:presence, `channel`, [{pid(), {user_id, user_info}}]
  """
  def subscribe!(channel, channel_data) do
    decoded_channel_data = :jsx.decode(channel_data)
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
  This function checks if the user that is leaving the presence channel
  have more than one connection subscribed.

  If the connection is unique, fire up the member_removed event
  Otherwise decrement the counter
  """
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
      else
        nil
      end
    end
    Enum.each(channel_user_id, member_remove_fun)
    :ok
  end

  def presence_channel?(<< "presence-", _presence_channel :: binary >> = _channel) do
    true
  end
  def presence_channel?(_) do
    false
  end

  defp sanitize_user_id(user_id) do
    case :jsx.is_term(user_id) do
      true -> :jsx.encode(user_id)
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
