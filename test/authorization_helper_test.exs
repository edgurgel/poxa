defmodule Poxa.AuthorizarionHelperTest do
  use ExUnit.Case, async: true
  alias Poxa.Authentication
  import Mimic
  import Poxa.AuthorizationHelper

  setup :verify_on_exit!

  setup do
    stub(Authentication)
    stub(:cowboy_req)
    :ok
  end

  test "is_authorized returns true if Authentication is ok" do
    expect(:cowboy_req, :body, fn :req -> {:ok, :body, :req1} end)
    expect(:cowboy_req, :method, fn :req1 -> {:method, :req2} end)
    expect(:cowboy_req, :qs_vals, fn :req2 -> {:qs_vals, :req3} end)
    expect(:cowboy_req, :path, fn :req3 -> {:path, :req4} end)
    expect(Authentication, :check, fn _, _, _, _ -> true end)

    assert is_authorized(:req, :state) == {true, :req4, :state}
  end

  test "is_authorized returns false if Authentication is not ok" do
    expect(:cowboy_req, :body, fn :req -> {:ok, :body, :req1} end)
    expect(:cowboy_req, :method, fn :req1 -> {:method, :req2} end)
    expect(:cowboy_req, :qs_vals, fn :req2 -> {:qs_vals, :req3} end)
    expect(:cowboy_req, :path, fn :req3 -> {:path, :req4} end)
    expect(Authentication, :check, fn _, _, _, _ -> false end)

    assert is_authorized(:req, :state) == {{false, "authentication failed"}, :req4, nil}
  end
end

