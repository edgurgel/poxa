defmodule Poxa.SocketIdTest do
  use ExUnit.Case
  alias Poxa.SocketId
  import :meck
  doctest SocketId

  setup do
    new Poxa.registry
    on_exit fn -> unload end
    :ok
  end

  test "generate! returns a string of 2 integers" do
    socket_id = SocketId.generate!
    [part1, part2] = String.split(socket_id, ".")

    assert {_, ""} = Integer.parse(part1)
    assert {_, ""} = Integer.parse(part2)
  end

  test "register!" do
    expect(Poxa.registry, :register!, [:socket_id, "socket_id"], :ok)

    assert SocketId.register!("socket_id") == :ok

    assert validate Poxa.registry
  end

  test "mine" do
    expect(Poxa.registry, :fetch, [:socket_id], "socket_id")

    assert SocketId.mine == "socket_id"

    assert validate Poxa.registry
  end

  test "mine without the socket_id" do
    expect(Poxa.registry, :fetch, [:socket_id], fn _ -> :meck.exception(:error, :badarg) end)

    assert_raise ArgumentError, fn ->
      SocketId.mine
    end

    assert validate Poxa.registry
  end
end
