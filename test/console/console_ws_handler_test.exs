defmodule Poxa.Console.WSHandlerTest do
  use ExUnit.Case
  alias Poxa.Authentication
  alias Poxa.Event
  import :meck
  import Poxa.Console.WSHandler

  setup do
    new Authentication
    new :cowboy_req
    new Event
    on_exit fn -> unload() end
    :ok
  end

  test "websocket_init with correct signature" do
    expect(:cowboy_req, :method, 1, {:method, :req2})
    expect(:cowboy_req, :path, 1, {:path, :req3})
    expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req4})
    expect(Authentication, :check, [{[:method, :path, "", :qs_vals], true}])
    expect(Event, :add_handler, [{[{Poxa.Console, self()}, self()], :ok}])

    assert websocket_init(:tranport, :req, []) == {:ok, :req4, nil}

    assert validate Authentication
    assert validate :cowboy_req
  end

  test "websocket_init with incorrect signature" do
    expect(:cowboy_req, :method, 1, {:method, :req2})
    expect(:cowboy_req, :path, 1, {:path, :req3})
    expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req4})
    expect(Authentication, :check, [{[:method, :path, "", :qs_vals], false}])

    assert websocket_init(:tranport, :req, []) == {:shutdown, :req4}

    assert validate Authentication
    assert validate :cowboy_req
  end
end
