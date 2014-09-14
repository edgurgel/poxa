defmodule Poxa.PresenceChannel do
  #defstruct [:name, :user_id, :user_info]
  #@type t :: %__MODULE__{name: binary, user_id: binary, user_info: term}
  @doc """
  This function returns the user ids currently subscribed to a presence channel

  More info at: http://pusher.com/docs/rest_api#method-get-users
  """
  #@spec users(binary) :: [user_id]
  def users(channel) do
    match = {{:p, :l, {:pusher, channel}}, :_, :'$1'}
    :gproc.select([{match, [], [:'$1']}])
    |> Enum.uniq(fn {user_id, _} -> user_id end)
    |> Enum.map(fn {user_id, _} -> user_id end)
  end

  @doc """
  Returns the number of unique users on a presence channel
  """
  @spec user_count(binary) :: non_neg_integer
  def user_count(channel) do
    match = {{:p, :l, {:pusher, channel}}, :_, :'$1'}
    :gproc.select([{match, [], [:'$1']}])
    |> Enum.uniq(fn {user_id, _} -> user_id end)
    |> Enum.count
  end
end
