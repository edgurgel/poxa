defmodule Poxa.UsersHandlerTest do
  use ExUnit.Case
  alias Poxa.PresenceSubscription
  import :meck
  import Poxa.UsersHandler

  setup do
    new JSEX
    new PresenceSubscription
    new :cowboy_req
  end

  teardown do
    unload JSEX
    unload PresenceSubscription
    unload :cowboy_req
  end

  test "malformed_request returns false and the channel if we have a presence channel" do
    expect(:cowboy_req, :binding, 2, {:presence_channel, :req})
    expect(PresenceSubscription, :presence_channel?, 1, true)
    assert malformed_request(:req, :state) == {false, :req, :presence_channel}
    assert validate(PresenceSubscription)
    assert validate :cowboy_req
  end

  test "malformed_request returns true and the channel if we have a presence channel" do
    expect(:cowboy_req, :binding, 2, {:presence_channel, :req})
    expect(PresenceSubscription, :presence_channel?, 1, false)
    assert malformed_request(:req, :state) == {true, :req, :presence_channel}
    assert validate(PresenceSubscription)
    assert validate :cowboy_req
  end

  test "get_json returns users of a presence channel" do
    expect(PresenceSubscription, :users, 1, ["user1", "user2"])
    expected = [users: [[id: "user1"], [id: "user2"]]]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, "channel123") == {:encoded_json, :req, nil}

    assert validate PresenceSubscription
    assert validate JSEX
  end

end
