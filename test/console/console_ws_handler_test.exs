defmodule Poxa.Console.WSHandlerTest do
  use ExUnit.Case
  alias Poxa.Authentication
  import :meck
  import Poxa.Console.WSHandler

  setup do
    new Authentication
    new :cowboy_req
    new :gproc
  end

  teardown do
    unload Authentication
    unload :cowboy_req
    unload :gproc
  end

  test "websocket_init with correct signature" do
    expect(:cowboy_req, :method, 1, {:method, :req2})
    expect(:cowboy_req, :path, 1, {:path, :req3})
    expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req4})
    expect(Authentication, :check, [{[:method, :path, "", :qs_vals], :ok}])
    expect(:gproc, :reg, 1, :ok)

    assert websocket_init(:tranport, :req, []) == {:ok, :req4, nil}

    assert validate Authentication
    assert validate :cowboy_req
    assert validate :gproc
  end

  test "websocket_init with incorrect signature" do
    expect(:cowboy_req, :method, 1, {:method, :req2})
    expect(:cowboy_req, :path, 1, {:path, :req3})
    expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req4})
    expect(Authentication, :check, [{[:method, :path, "", :qs_vals], :error}])

    assert websocket_init(:tranport, :req, []) == {:shutdown, :req4}

    assert validate Authentication
    assert validate :cowboy_req
  end

  test "websocket_terminate always say goodbye" do
    expect(:gproc, :goodbye, 0, :ok)

    assert websocket_terminate(:reason, :req, :state) == :ok

    assert validate :gproc
  end
end
