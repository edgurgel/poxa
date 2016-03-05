defmodule Poxa.SocketIdTest do
  use ExUnit.Case
  alias Poxa.SocketId
  doctest SocketId

  test "generate! returns a string of 2 integers" do
    socket_id = SocketId.generate!
    [part1, part2] = String.split(socket_id, ".")

    assert {_, ""} = Integer.parse(part1)
    assert {_, ""} = Integer.parse(part2)
  end

  test "register!" do
    SocketId.register!("my_socket_id")
    assert :gproc.get_value({:p, :l, :socket_id}) == "my_socket_id"
  end

  test "mine" do
    :gproc.reg({:p, :l, :socket_id}, "my_socket_id")
    assert SocketId.mine == "my_socket_id"
  end

  test "mine without the socket_id" do
    assert_raise ArgumentError, fn ->
      SocketId.mine
    end
  end
end
