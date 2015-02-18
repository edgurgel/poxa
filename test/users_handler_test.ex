defmodule Poxa.UsersHandlerTest do
  use ExUnit.Case
  alias Poxa.PresenceChannel
  import :meck
  import Poxa.UsersHandler

  setup do
    new JSX
    new PresenceChannel
    new :cowboy_req
    on_exit fn -> unload end
    :ok
  end

  test "malformed_request returns false if we have a presence channel" do
    expect(:cowboy_req, :binding, 2, {"presence-channel", :req})

    assert malformed_request(:req, :state) == {false, :req, "presence-channel"}

    assert validate(PresenceChannel)
    assert validate :cowboy_req
  end

  test "malformed_request returns true if we don't have a presence channel" do
    expect(:cowboy_req, :binding, 2, {"private-channel", :req})

    assert malformed_request(:req, :state) == {true, :req, "private-channel"}

    assert validate :cowboy_req
  end

  test "get_json returns users of a presence channel" do
    expect(PresenceChannel, :users, 1, ["user1", "user2"])
    expected = [users: [[id: "user1"], [id: "user2"]]]
    expect(JSX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, "channel123") == {:encoded_json, :req, nil}

    assert validate PresenceChannel
    assert validate JSX
  end

end
