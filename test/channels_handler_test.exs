defmodule Poxa.ChannelsHandlerTest do
  use ExUnit.Case
  alias Poxa.Channel
  alias Poxa.PresenceChannel
  import :meck
  import Poxa.ChannelsHandler

  setup do
    new JSEX
    new :cowboy_req
    on_exit fn -> unload end
    :ok
  end

  test "malformed_request on multiple channels" do
    expect(:cowboy_req, :qs_val, 3, {"subscription_count", :req})
    expect(:cowboy_req, :binding, 3, {nil, :req})

    assert malformed_request(:req, :state) == {false, :req, nil}

    assert validate :cowboy_req
  end

  test "malformed_request on single channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"subscription_count,message_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})

    assert malformed_request(:req, :state) == {true, :req, {"channel", ["subscription_count", "message_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single channel with invalid attribute" do
    expect(:cowboy_req, :qs_val, 3, {"message_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})

    assert malformed_request(:req, :state) == {true, :req, {"channel", ["message_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single channel with valid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"subscription_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})

    assert malformed_request(:req, :state) == {false, :req, {"channel", ["subscription_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single non presence-channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"user_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})

    assert malformed_request(:req, :state) == {true, :req, {"channel", ["user_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single presence-channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"user_count,subscription_count", :req})
    expect(:cowboy_req, :binding, 3, {"presence-channel", :req})

    assert malformed_request(:req, :state) == {false, :req, {"presence-channel", ["user_count", "subscription_count"]}}

    assert validate :cowboy_req
  end

  test "get_json on a specific channel with subscription_count attribute" do
    expect(Channel, :occupied?, 1, true)
    expect(Channel, :subscription_count, 1, 5)
    expected = [occupied: true, subscription_count: 5]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:channel, ["subscription_count"]}) == {:encoded_json, :req, nil}

    assert validate JSEX
    assert validate Channel
  end

  test "get_json on a specific channel with user_count attribute" do
    expect(Channel, :occupied?, 1, true)
    expect(PresenceChannel, :user_count, 1, 3)
    expected = [occupied: true, user_count: 3]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:channel, ["user_count"]}) == {:encoded_json, :req, nil}

    assert validate JSEX
    assert validate Channel
    assert validate PresenceChannel
  end

  test "get_json on a specific channel with user_count and subscription_count attributes" do
    expect(Channel, :occupied?, 1, true)
    expect(Channel, :subscription_count, 1, 5)
    expect(PresenceChannel, :user_count, 1, 3)
    expected = [occupied: true, subscription_count: 5, user_count: 3]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:channel, ["subscription_count", "user_count"]}) == {:encoded_json, :req, nil}

    assert validate JSEX
    assert validate Channel
    assert validate PresenceChannel
  end

  test "get_json on every single channel" do
    expect(:cowboy_req, :qs_val, 3, {nil, :req})
    expect(Channel, :all, 0, ["presence-channel", "private-channel"])
    expect(Channel, :presence?, 1, true)
    expect(PresenceChannel, :user_count, 1, 3)
    expected = [channels: [{"presence-channel", user_count: 3}]]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, nil) == {:encoded_json, :req, nil}

    assert validate JSEX
    assert validate Channel
    assert validate PresenceChannel
  end

  test "get_json on every single channel with filter" do
    expect(:cowboy_req, :qs_val, 3, {"poxa-", :req})
    expect(Channel, :all, 0, ["presence-channel", "poxa-channel"])
    expect(Channel, :presence?, 1, false)
    expect(Channel, :subscription_count, 1, 9)
    expected = [channels: [{"poxa-channel", user_count: 9}]]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, nil) == {:encoded_json, :req, nil}

    assert validate JSEX
    assert validate Channel
  end
end
