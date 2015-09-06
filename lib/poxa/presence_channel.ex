defmodule Poxa.PresenceChannel do
  @moduledoc """
  This module holds functions that are related to presence channel users information
  """

  @doc """
  This function returns the user ids currently subscribed to a presence channel

  More info at: http://pusher.com/docs/rest_api#method-get-users
  """
  @spec users(binary, binary) :: [binary | integer]
  def users(channel, app_id) do
    match = {{:p, :l, {:pusher, app_id, channel}}, :_, :'$1'}
    :gproc.select([{match, [], [:'$1']}])
    |> Enum.uniq(fn {user_id, _} -> user_id end)
    |> Enum.map(fn {user_id, _} -> user_id end)
  end

  @doc """
  Returns the number of unique users on a presence channel
  """
  @spec user_count(binary, binary) :: non_neg_integer
  def user_count(channel, app_id) do
    match = {{:p, :l, {:pusher, app_id, channel}}, :_, :'$1'}
    :gproc.select([{match, [], [:'$1']}])
    |> Enum.uniq(fn {user_id, _} -> user_id end)
    |> Enum.count
  end
end
