defmodule Poxa.Channel do
  @moduledoc """
  A module to work with channels

  Channels can be public, private or presence channels.
  """

  alias Poxa.Registry

  @doc """
  Returns true if the channel name is valid and false otherwise

  iex> Poxa.Channel.valid? "private-channel"
  true
  iex> Poxa.Channel.valid? "channel_name-1"
  true
  iex> Poxa.Channel.valid? "channel:presence-abcd"
  false
  """
  def valid?(channel) do
    Regex.match?(~r/\A[\w\-=@,.;]+\z/, channel)
  end

  @doc """
  Returns true for `private-*`

  iex> Poxa.Channel.private?("private-ch")
  true
  iex> Poxa.Channel.private?("ch")
  false
  iex> Poxa.Channel.private?("presence-ch")
  false
  """
  def private?("private-" <> _), do: true
  def private?(_), do: false

  @doc """
  Returns true for `presence-*`

  iex> Poxa.Channel.presence?("private-ch")
  false
  iex> Poxa.Channel.presence?("ch")
  false
  iex> Poxa.Channel.presence?("presence-ch")
  true
  """
  def presence?("presence-" <> _), do: true
  def presence?(_), do: false

  @doc """
  Returns true for `presence-*` or `private-*`

  iex> Poxa.Channel.private_or_presence?("private-ch")
  true
  iex> Poxa.Channel.private_or_presence?("ch")
  false
  iex> Poxa.Channel.private_or_presence?("presence-ch")
  true
  """
  def private_or_presence?(channel) do
    private?(channel) or presence?(channel)
  end

  @doc """
  Returns true if prefix matches channel

  iex> Poxa.Channel.matches?("foo-bar", "foo-")
  true
  iex> Poxa.Channel.matches?("foo-bar", "bar-")
  false
  iex> Poxa.Channel.matches?("foo-bar", "")
  false
  iex> Poxa.Channel.matches?("foo-bar", nil)
  false
  iex> Poxa.Channel.matches?("foo-bar", "foo-bartman")
  false
  """
  def matches?(_, nil), do: false
  def matches?(_, ""), do: false
  def matches?(channel, prefix) do
    base = byte_size(prefix)
    case channel do
      <<^prefix :: binary-size(base), _ :: binary>> -> true
      _ -> false
    end
  end

  @doc """
  Returns true if the channel has at least 1 subscription
  """
  @spec occupied?(binary) :: boolean
  def occupied?(channel) do
    Registry.occupied?(channel)
  end

  @doc """
  Returns the list of channels the `pid` is subscribed
  """
  @spec all(pid | :_) :: [binary]
  def all(pid \\ :_) do
    Registry.channels(pid)
  end

  @doc """
  Returns true if `pid` is subscribed to `channel` and false otherwise
  """
  @spec subscribed?(binary, pid) :: boolean
  def subscribed?(channel, pid) do
    Registry.subscribed?(channel, pid)
  end

  @doc """
  Returns how many connections are opened on the `channel`
  """
  @spec subscription_count(binary) :: non_neg_integer
  def subscription_count(channel) do
    Registry.subscription_count(channel)
  end
end
