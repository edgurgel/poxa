defmodule Poxa.Subscription do
  @moduledoc """
  This module contains functions to handle subscription and unsubscription
  on channels, public, private and presence channels.
  """
  alias Poxa.AuthSignature
  alias Poxa.PresenceSubscription
  require Lager

  @doc """
  Subscribe to a channel on this process.
  Returns :ok to public and private channels and
  {:presence, channel, channel_data} to presence channel
  """
  @spec subscribe!(:jsx.json_term, binary) :: :ok | {:presence, binary, {PresenceSubscription.user_id,
                                                                          :jsx.json_term}} | :error
  def subscribe!(data, socket_id) do
    channel = data["channel"]
    case channel do
      "private-" <> _private_channel ->
        to_sign = case data["channel_data"] do
          nil -> << socket_id :: binary, ":", channel :: binary >>
          channel_data -> << socket_id :: binary, ":", channel :: binary, ":", channel_data :: binary >>
        end
        case AuthSignature.validate(to_sign, data["auth"]) do
          :ok -> subscribe_channel(channel)
          :error -> subscribe_error(channel)
        end
      "presence-" <> _presence_channel ->
        channel_data = ListDict.get(data, "channel_data", "undefined")
        to_sign = <<socket_id :: binary, ":", channel ::binary, ":", channel_data :: binary>>
        case AuthSignature.validate(to_sign, data["auth"]) do
          :ok -> PresenceSubscription.subscribe!(channel, channel_data)
          :error -> subscribe_error(channel)
        end
      nil ->
        Lager.info("Missing channel")
        :error
      _ -> subscribe_channel(channel)
    end
  end

  defp subscribe_error(channel) do
    Lager.info("Error while subscribing to channel ~p", [channel])
    :error
  end

  defp subscribe_channel(channel) do
    Lager.info("Subscribing to channel ~p", [channel])
    if subscribed?(channel) do
      Lager.info("Already subscribed ~p on channel ~p", [self, channel])
    else
      Lager.info("Registering ~p to channel ~p", [self, channel])
      :gproc.reg({:p, :l, {:pusher, channel}})
    end
    {:ok, channel}
  end

  @doc """
  Unsubscribe to a channel always returning :ok
  """
  @spec unsubscribe!(:jsx.json_term) :: :ok
  def unsubscribe!(data) do
    channel = data["channel"]
    if PresenceSubscription.presence_channel?(channel) do
      PresenceSubscription.unsubscribe!(channel);
    end
    unsubscribe_channel(channel)
  end

  defp unsubscribe_channel(channel) do
    Lager.info("Unsubscribing to channel ~p", [channel])
    case subscribed?(channel) do
      true -> :gproc.unreg({:p, :l, {:pusher, channel}});
      false -> Lager.debug("Already subscribed")
    end
    :ok
  end

  @doc """
  Returns true if subscribed to `channel` and false otherwise
  """
  @spec subscribed?(binary) :: boolean
  def subscribed?(channel) do
    match = {{:p, :l, {:pusher, channel}}, self, :_}
    case :gproc.select([{match, [], [:'$$']}]) do
      [] -> false;
      _ -> true
    end
  end

  @doc """
  Returns how many connections are opened on the `channel`
  """
  @spec subscription_count(binary) :: non_neg_integer
  def subscription_count(channel) do
    match = {{:p, :l, {:pusher, channel}}, :_, :_}
    :gproc.select_count([{match, [], [true]}])
  end

  @doc """
  Returns true if the channel has at least 1 subscription
  """
  @spec occupied?(binary) :: boolean
  def occupied?(channel) do
    match = {{:p, :l, {:pusher, channel}}, :_, :_}
    :gproc.select(:all, [{match, [], [true]}], 1) != :'$end_of_table'
  end

  @doc """
  Returns the list of channels with at least 1 subscription
  """
  @spec all_channels :: [binary]
  def all_channels do
    match = {{:p, :l, {:pusher, :'$1'}}, :_, :_}
    :gproc.select([{match, [], [:'$1']}])
    |> Enum.uniq
  end

end
