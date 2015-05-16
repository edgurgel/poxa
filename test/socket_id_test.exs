defmodule Poxa.SocketIdTest do
  use ExUnit.Case
  alias Poxa.SocketId

  setup_all do
    :random.seed
    :ok
  end

  test "generate! returns a string of 2 integers" do
    socket_id = SocketId.generate!
    [part1, part2] = String.split(socket_id, ".")

    {int1, ""} = Integer.parse(part1)
    {int2, ""} = Integer.parse(part1)

    assert is_integer(int1) and is_integer(int2)
  end
end
