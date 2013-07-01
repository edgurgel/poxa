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

  test "malformed_request returns false and the channel if we have a presence channel" do
    :meck.expect(:cowboy_req, :binding, 2, {:presence_channel, :req})
    :meck.expect(PresenceSubscription, :presence_channel?, 1, true)
    assert malformed_request(:req, :state) == {false, :req, :presence_channel}
    assert :meck.validate(PresenceSubscription)
    assert :meck.validate(:cowboy_req)
  end

  test "malformed_request returns true and the channel if we have a presence channel" do
    :meck.expect(:cowboy_req, :binding, 2, {:presence_channel, :req})
    :meck.expect(PresenceSubscription, :presence_channel?, 1, false)
    assert malformed_request(:req, :state) == {true, :req, :presence_channel}
    assert :meck.validate(PresenceSubscription)
    assert :meck.validate(:cowboy_req)
  end

  test "resource_exists returns users if the channel is a presence_channel" do
    :meck.expect(PresenceSubscription, :users, 1, :user_ids)
    assert resource_exists(:req, :state) == {true, :req, :user_ids}
    assert :meck.validate(PresenceSubscription)
    assert :meck.validate(:cowboy_req)
  end

  test "resource_exists returns false if the channel is not a presence_channel" do
    :meck.expect(:cowboy_req, :binding, 2, {:presence_channel, :req})
    assert resource_exists(:req, :state) == {false, :req, nil}
    assert :meck.validate(:cowboy_req)
  end

end
