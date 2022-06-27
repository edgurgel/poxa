defmodule Poxa.PresenceChannel do
  @moduledoc """
  This module holds functions that are related to presence channel users information
  """

  @doc """
  This function returns the user ids currently subscribed to a presence channel

  More info at: http://pusher.com/docs/rest_api#method-get-users
  """
  @spec users(binary) :: [binary | integer]
  def users(channel) do
    for {user_id, _} <- Poxa.registry().unique_subscriptions(channel), do: user_id
  end

  @doc """
  Returns the number of unique users on a presence channel
  """
  @spec user_count(binary) :: non_neg_integer
  def user_count(channel), do: channel |> users |> Enum.count()

  @doc """
  Returns user data for a presence channel
  """
  @spec my_user_id(binary) :: {binary, map} | nil
  def my_user_id(channel) do
    case Poxa.registry().fetch(channel) do
      %{user_id: user_id} -> user_id
      _ -> nil
    end
  end
end
