defmodule Poxa.SocketIdTest do
  use ExUnit.Case, async: true
  alias Poxa.SocketId
  use Mimic
  doctest SocketId

  setup do
    stub(Poxa.registry())
    :ok
  end

  test "generate! returns a string of 2 integers" do
    socket_id = SocketId.generate!()
    [part1, part2] = String.split(socket_id, ".")

    assert {_, ""} = Integer.parse(part1)
    assert {_, ""} = Integer.parse(part2)
  end

  test "register!" do
    expect(Poxa.registry(), :register!, fn :socket_id, "socket_id" -> :ok end)

    assert SocketId.register!("socket_id") == :ok
  end

  test "mine" do
    expect(Poxa.registry(), :fetch, fn :socket_id -> "socket_id" end)

    assert SocketId.mine() == "socket_id"
  end

  test "mine without the socket_id" do
    expect(Poxa.registry(), :fetch, fn :socket_id -> raise ArgumentError end)

    assert_raise ArgumentError, fn ->
      SocketId.mine()
    end
  end
end
