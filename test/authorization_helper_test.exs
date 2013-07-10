Code.require_file "test_helper.exs", __DIR__

defmodule PoxaAuthorizarionHelperTest do
  use ExUnit.Case
  alias Poxa.Authentication
  import Poxa.AuthorizationHelper

  setup do
    :meck.new Authentication
    :meck.new :cowboy_req
  end

  teardown do
    :meck.unload Authentication
    :meck.unload :cowboy_req
  end

  test "is_authorized returns true if Authentication is ok" do
    :meck.expect(:cowboy_req, :body, 1, {:ok, :body, :req1})
    :meck.expect(:cowboy_req, :method, 1, {:method, :req2})
    :meck.expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req3})
    :meck.expect(:cowboy_req, :path, 1, {:path, :req4})
    :meck.expect(Authentication, :check, 4, :ok)
    assert is_authorized(:req, :state) == {true, :req4, :state}
    assert :meck.validate(Authentication)
    assert :meck.validate(:cowboy_req)
  end

  test "is_authorized returns false if Authentication is not ok" do
    :meck.expect(:cowboy_req, :body, 1, {:ok, :body, :req1})
    :meck.expect(:cowboy_req, :method, 1, {:method, :req2})
    :meck.expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req3})
    :meck.expect(:cowboy_req, :path, 1, {:path, :req4})
    :meck.expect(Authentication, :check, 4, {:badauth, "error"})
    assert is_authorized(:req, :state) == {{false, "authentication failed"}, :req4, nil}
    assert :meck.validate(Authentication)
    assert :meck.validate(:cowboy_req)
  end

end

