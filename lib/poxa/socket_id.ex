defmodule Poxa.SocketId do
  @moduledoc """
  Helper macros for generating and verifying socket ids.
  """

  @doc """
  Generates a string on the form 123.456
  """
  @spec generate! :: binary
  def generate! do
    <<part1::32, part2::32>> = :crypto.rand_bytes(8)
    "#{part1}.#{part2}"
  end

  @doc """
  Returns wheter a socket id is valid or not.

  iex> Poxa.SocketId.valid? "123.456"
  true
  iex> Poxa.SocketId.valid? "123456"
  false
  iex> Poxa.SocketId.valid? "123.456:channel-private"
  false
  """
  def valid?(socket_id) do
    Regex.match?(~r/\A\d+\.\d+\z/, socket_id)
  end
end
