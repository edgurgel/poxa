defmodule Poxa.SocketId do
  @doc """
  Generates a string on the form 123.456
  """
  @spec generate! :: binary
  def generate! do
    <<part1::32, part2::32>> = :crypto.rand_bytes(8)
    "#{part1}.#{part2}"
  end
end
