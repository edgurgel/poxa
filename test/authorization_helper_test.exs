defmodule Poxa.AuthorizarionHelperTest do
  use ExUnit.Case, async: true
  alias Poxa.Authentication
  use Mimic
  import Poxa.AuthorizationHelper

  setup do
    stub(Authentication)
    stub(:cowboy_req)
    :ok
  end

  test "is_authorized returns true if Authentication is ok" do
    expect(:cowboy_req, :read_body, fn :req -> {:ok, :body, :req1} end)
    expect(:cowboy_req, :method, fn :req1 -> :method end)
    expect(:cowboy_req, :parse_qs, fn :req1 -> :qs_vals end)
    expect(:cowboy_req, :path, fn :req1 -> :path end)
    expect(Authentication, :check, fn _, _, _, _ -> true end)

    assert is_authorized(:req, :state) == {true, :req1, :state}
  end

  test "is_authorized returns false if Authentication is not ok" do
    expect(:cowboy_req, :read_body, fn :req -> {:ok, :body, :req1} end)
    expect(:cowboy_req, :method, fn :req1 -> :method end)
    expect(:cowboy_req, :parse_qs, fn :req1 -> :qs_vals end)
    expect(:cowboy_req, :path, fn :req1 -> :path end)
    expect(Authentication, :check, fn _, _, _, _ -> false end)

    assert is_authorized(:req, :state) == {{false, "authentication failed"}, :req1, nil}
  end
end
