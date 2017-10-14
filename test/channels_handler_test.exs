defmodule Poxa.ChannelsHandlerTest do
  use ExUnit.Case
  alias Poxa.Channel
  alias Poxa.PresenceChannel
  import :meck
  import Poxa.ChannelsHandler

  setup do
    new Poison
    new :cowboy_req
    on_exit fn -> unload() end
    :ok
  end

  test "malformed_request on multiple channels with no attributes" do
    expect(:cowboy_req, :qs_val, 3, seq([{"", :req}, {nil, :req}]))
    expect(:cowboy_req, :binding, 3, {nil, :req})

    assert malformed_request(:req, :state) == {false, :req, {:all, nil, []}}

    assert validate :cowboy_req
  end

  test "malformed_request on multiple channels with valid attributes" do
    expect(:cowboy_req, :qs_val, 3, seq([{"subscription_count", :req}, {nil, :req}]))
    expect(:cowboy_req, :binding, 3, {nil, :req})

    assert malformed_request(:req, :state) == {false, :req, {:all, nil, ["subscription_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on multiple channels with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, seq([{"user_count", :req}, {nil, :req}]))
    expect(:cowboy_req, :binding, 3, {nil, :req})

    assert malformed_request(:req, :state) == {true, :req, {:all, nil, ["user_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on multiple channels with filter" do
    expect(:cowboy_req, :qs_val, 3, seq([{"", :req}, {"poxa-", :req}]))
    expect(:cowboy_req, :binding, 3, {nil, :req})

    assert malformed_request(:req, :state) == {false, :req, {:all, "poxa-", []}}

    assert validate :cowboy_req
  end

  test "malformed_request on multiple channels with presence filter and user_count attribute" do
    expect(:cowboy_req, :qs_val, 3, seq([{"user_count", :req}, {"presence-", :req}]))
    expect(:cowboy_req, :binding, 3, {nil, :req})

    assert malformed_request(:req, :state) == {false, :req, {:all, "presence-", ["user_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"subscription_count,message_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})

    assert malformed_request(:req, :state) == {true, :req, {:one, "channel", ["subscription_count", "message_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single channel with invalid attribute" do
    expect(:cowboy_req, :qs_val, 3, {"message_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})

    assert malformed_request(:req, :state) == {true, :req, {:one, "channel", ["message_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single channel with valid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"subscription_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})

    assert malformed_request(:req, :state) == {false, :req, {:one, "channel", ["subscription_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single non presence-channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"user_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})

    assert malformed_request(:req, :state) == {true, :req, {:one, "channel", ["user_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single presence-channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"user_count,subscription_count", :req})
    expect(:cowboy_req, :binding, 3, {"presence-channel", :req})

    assert malformed_request(:req, :state) == {false, :req, {:one, "presence-channel", ["user_count", "subscription_count"]}}

    assert validate :cowboy_req
  end

  test "get_json on a specific channel with subscription_count attribute" do
    expect(Channel, :occupied?, 1, true)
    expect(Channel, :subscription_count, 1, 5)
    expected = [occupied: true, subscription_count: 5]
    expect(Poison, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:one, :channel, ["subscription_count"]}) == {:encoded_json, :req, nil}

    assert validate Poison
    assert validate Channel
  end

  test "get_json on a specific channel with user_count attribute" do
    expect(Channel, :occupied?, 1, true)
    expect(PresenceChannel, :user_count, 1, 3)
    expected = [occupied: true, user_count: 3]
    expect(Poison, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:one, :channel, ["user_count"]}) == {:encoded_json, :req, nil}

    assert validate Poison
    assert validate Channel
    assert validate PresenceChannel
  end

  test "get_json on a specific channel with user_count and subscription_count attributes" do
    expect(Channel, :occupied?, 1, true)
    expect(Channel, :subscription_count, 1, 5)
    expect(PresenceChannel, :user_count, 1, 3)
    expected = [occupied: true, subscription_count: 5, user_count: 3]
    expect(Poison, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:one, :channel, ["subscription_count", "user_count"]}) == {:encoded_json, :req, nil}

    assert validate Poison
    assert validate Channel
    assert validate PresenceChannel
  end

  test "get_json on every single channel" do
    expect(:cowboy_req, :qs_val, 3, {nil, :req})
    expect(Channel, :all, 0, ["presence-channel", "private-channel"])
    expect(Channel, :presence?, 1, true)
    expect(PresenceChannel, :user_count, 1, 3)
    expected = [channels: [{"presence-channel", user_count: 3}]]
    expect(Poison, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:all, nil, ["user_count"]}) == {:encoded_json, :req, nil}

    assert validate Poison
    assert validate Channel
    assert validate PresenceChannel
  end

  test "get_json on every single channel with filter" do
    expect(Channel, :all, 0, ["presence-channel", "poxa-channel"])
    expect(Channel, :matches?, 2, seq([false, true]))
    expected = [channels: [{"poxa-channel", []}]]
    expect(Poison, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:all, 'poxa-', []}) == {:encoded_json, :req, nil}

    assert validate Poison
    assert validate Channel
  end
end
