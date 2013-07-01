Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.UsersHandlerTest do
  use ExUnit.Case
  alias Poxa.Authentication
  alias Poxa.PresenceSubscription
  import Poxa.UsersHandler

  setup do
    :meck.new Authentication
    :meck.new JSEX
    :meck.new PresenceSubscription
    :meck.new :cowboy_req
  end

  teardown do
    :meck.unload Authentication
    :meck.unload JSEX
    :meck.unload PresenceSubscription
    :meck.unload :cowboy_req
  end

  test "is_authorized returns true if signature is ok" do
    :meck.expect(:cowboy_req, :body, 1, {:ok, :body, :req})
    :meck.expect(:cowboy_req, :method, 1, {:method, :req})
    :meck.expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req})
    :meck.expect(:cowboy_req, :path, 1, {:path, :req})
    :meck.expect(Authentication, :check, 4, :ok)
    assert is_authorized(:req, :state) == {true, :req, :state}
    assert :meck.validate(Authentication)
    assert :meck.validate(:cowboy_req)
  end

  test "is_authorized returns false if signature is not ok" do
    :meck.expect(:cowboy_req, :body, 1, {:ok, :body, :req})
    :meck.expect(:cowboy_req, :method, 1, {:method, :req})
    :meck.expect(:cowboy_req, :qs_vals, 1, {:qs_vals, :req})
    :meck.expect(:cowboy_req, :path, 1, {:path, :req})
    :meck.expect(Authentication, :check, 4, :error)
    assert is_authorized(:req, :state) == {{false, "authentication failed"}, :req, :state}
    assert :meck.validate(Authentication)
    assert :meck.validate(:cowboy_req)
  end

  test "resource_exists returns users if the channel is a presence_channel" do
    :meck.expect(:cowboy_req, :binding, 2, {:presence_channel, :req})
    :meck.expect(PresenceSubscription, :presence_channel?, 1, true)
    :meck.expect(PresenceSubscription, :users, 1, :user_ids)
    assert resource_exists(:req, :state) == {true, :req, :user_ids}
    assert :meck.validate(PresenceSubscription)
    assert :meck.validate(:cowboy_req)
  end

  test "resource_exists returns false if the channel is not a presence_channel" do
    :meck.expect(:cowboy_req, :binding, 2, {:presence_channel, :req})
    :meck.expect(PresenceSubscription, :presence_channel?, 1, false)
    assert resource_exists(:req, :state) == {false, :req, nil}
    assert :meck.validate(PresenceSubscription)
    assert :meck.validate(:cowboy_req)
  end

end
