defmodule Poxa.PresenceChannel do
  @moduledoc """
  This module holds functions that are related to presence channel users information
  """

  alias Poxa.Registry

  @doc """
  This function returns the user ids currently subscribed to a presence channel

  More info at: http://pusher.com/docs/rest_api#method-get-users
  """
  @spec users(binary) :: [binary | integer]
  def users(channel) do
    Registry.users(channel)
  end

  @doc """
  Returns the number of unique users on a presence channel
  """
  @spec user_count(binary) :: non_neg_integer
  def user_count(channel) do
    Registry.user_count(channel)
  end
end
