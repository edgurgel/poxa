defmodule Poxa.SocketId do
  @doc """
  Generates a string on the form 123.456
  """
  @spec generate! :: binary
  def generate! do
    <<part1::32, part2::32>> = :crypto.strong_rand_bytes(8)
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
  @spec valid?(binary) :: boolean
  def valid?(socket_id) do
    Regex.match?(~r/\A\d+\.\d+\z/, socket_id)
  end

  @doc """
  Register the `socket_id` as a property of the process
  """
  @spec register!(binary) :: true
  def register!(socket_id) do
    Poxa.registry().register!(:socket_id, socket_id)
  end

  @doc """
  Get the socket_id of the current process

  It throws an ArgumentError if the process has not socket_id
  """
  @spec mine :: binary
  def mine do
    Poxa.registry().fetch(:socket_id)
  end
end
