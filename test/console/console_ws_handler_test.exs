defmodule Poxa.Console.WSHandlerTest do
  use ExUnit.Case, async: true
  alias Poxa.Authentication
  alias Poxa.Event
  import Mimic
  import Poxa.Console.WSHandler

  setup :verify_on_exit!

  test "websocket_init with correct signature" do
    pid = self()
    expect(:cowboy_req, :method, fn :req -> {:method, :req2} end)
    expect(:cowboy_req, :path, fn :req2 -> {:path, :req3} end)
    expect(:cowboy_req, :qs_vals, fn :req3 -> {:qs_vals, :req4} end)
    expect(Authentication, :check, fn :method, :path, "", :qs_vals -> true end)
    expect(Event, :add_handler, fn {Poxa.Console, ^pid}, ^pid -> :ok end)

    assert websocket_init(:tranport, :req, []) == {:ok, :req4, nil}
  end

  test "websocket_init with incorrect signature" do
    expect(:cowboy_req, :method, fn :req -> {:method, :req2} end)
    expect(:cowboy_req, :path, fn :req2 -> {:path, :req3} end)
    expect(:cowboy_req, :qs_vals, fn :req3 -> {:qs_vals, :req4} end)
    expect(Authentication, :check, fn :method, :path, "", :qs_vals -> false end)

    assert websocket_init(:tranport, :req, []) == {:shutdown, :req4}
  end
end
