defmodule Poxa.ConsoleTest do
  use ExUnit.Case
  import :meck
  import Poxa.Console

  setup do
    new :gproc
    new JSEX
  end

  teardown do
    unload :gproc
    unload JSEX
  end

  test "connected" do
    expect(JSEX, :encode!, 1, :encoded_json)
    expect(:gproc, :send, 2, :ok)

    assert connected(:socket_id, "origin") == :ok

    assert validate JSEX
    assert validate :gproc
  end

  test "disconnected" do
    expect(JSEX, :encode!, 1, :encoded_json)
    expect(:gproc, :send, 2, :ok)

    assert disconnected(:socket_id, ["channel"]) == :ok

    assert validate JSEX
    assert validate :gproc
  end

  test "subscribed" do
    expect(JSEX, :encode!, 1, :encoded_json)
    expect(:gproc, :send, 2, :ok)

    assert subscribed(:socket_id, "channel") == :ok

    assert validate JSEX
    assert validate :gproc
  end

  test "unsubscribed" do
    expect(JSEX, :encode!, 1, :encoded_json)
    expect(:gproc, :send, 2, :ok)

    assert unsubscribed(:socket_id, "channel") == :ok

    assert validate JSEX
    assert validate :gproc
  end

  test "api_message" do
    expect(JSEX, :encode!, 1, :encoded_json)
    expect(:gproc, :send, 2, :ok)

    assert api_message("channel", %{"event" => "event-name"}) == :ok

    assert validate JSEX
    assert validate :gproc
  end

end
