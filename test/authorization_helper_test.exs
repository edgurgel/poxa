defmodule Poxa.AuthorizarionHelperTest do
  use ExUnit.Case
  alias Poxa.Authentication
  import :meck
  import Poxa.AuthorizationHelper

  setup do
    new Authentication
    new :cowboy_req
    on_exit fn -> unload() end
    :ok
  end

  test "is_authorized returns true if Authentication is ok" do
    expect(:cowboy_req, :body, 1, {:ok, :body, :req1})
    expect(:cowboy_req, :method, 1, {:method, :req2})
    expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req3})
    expect(:cowboy_req, :path, 1, {:path, :req4})
    expect(Authentication, :check, 4, true)
    assert is_authorized(:req, :state) == {true, :req4, :state}
    assert validate(Authentication)
    assert validate(:cowboy_req)
  end

  test "is_authorized returns false if Authentication is not ok" do
    expect(:cowboy_req, :body, 1, {:ok, :body, :req1})
    expect(:cowboy_req, :method, 1, {:method, :req2})
    expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req3})
    expect(:cowboy_req, :path, 1, {:path, :req4})
    expect(Authentication, :check, 4, false)
    assert is_authorized(:req, :state) == {{false, "authentication failed"}, :req4, nil}
    assert validate(Authentication)
    assert validate(:cowboy_req)
  end

end

