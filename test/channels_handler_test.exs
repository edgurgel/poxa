Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.ChannelsHandlerTest do
  use ExUnit.Case
  alias Poxa.PresenceSubscription
  alias Poxa.Subscription
  import :meck
  import Poxa.ChannelsHandler

  setup do
    new JSEX
    new PresenceSubscription
    new Subscription
    new :cowboy_req
  end

  teardown do
    unload JSEX
    unload PresenceSubscription
    unload Subscription
    unload :cowboy_req
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
    expect(PresenceSubscription, :presence_channel?, 1, false)

    assert malformed_request(:req, :state) == {true, :req, {"channel", ["subscription_count", "message_count"]}}

    assert validate PresenceSubscription
    assert validate :cowboy_req
  end

  test "malformed_request on single channel with invalid attribute" do
    expect(:cowboy_req, :qs_val, 3, {"message_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})
    expect(PresenceSubscription, :presence_channel?, 1, false)

    assert malformed_request(:req, :state) == {true, :req, {"channel", ["message_count"]}}

    assert validate PresenceSubscription
    assert validate :cowboy_req
  end

  test "malformed_request on single channel with valid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"subscription_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})
    expect(PresenceSubscription, :presence_channel?, 1, false)

    assert malformed_request(:req, :state) == {false, :req, {"channel", ["subscription_count"]}}

    assert validate PresenceSubscription
    assert validate :cowboy_req
  end

  test "malformed_request on single non presence-channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"user_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})
    expect(PresenceSubscription, :presence_channel?, 1, false)

    assert malformed_request(:req, :state) == {true, :req, {"channel", ["user_count"]}}

    assert validate PresenceSubscription
    assert validate :cowboy_req
  end

  test "malformed_request on single presence-channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"user_count,subscription_count", :req})
    expect(:cowboy_req, :binding, 3, {"presence-channel", :req})
    expect(PresenceSubscription, :presence_channel?, 1, true)

    assert malformed_request(:req, :state) == {false, :req, {"presence-channel", ["user_count", "subscription_count"]}}

    assert validate PresenceSubscription
    assert validate :cowboy_req
  end

  test "get_json on a specific channel with subscription_count attribute" do
    expect(Subscription, :occupied?, 1, true)
    expect(Subscription, :subscription_count, 1, 5)
    expected = [occupied: true, subscription_count: 5]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:channel, ["subscription_count"]}) == {:encoded_json, :req, nil}

    assert validate JSEX
    assert validate Subscription
  end

  test "get_json on a specific channel with user_count attribute" do
    expect(Subscription, :occupied?, 1, true)
    expect(PresenceSubscription, :user_count, 1, 3)
    expected = [occupied: true, user_count: 3]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:channel, ["user_count"]}) == {:encoded_json, :req, nil}

    assert validate JSEX
    assert validate Subscription
    assert validate PresenceSubscription
  end

  test "get_json on a specific channel with user_count and subscription_count attributes" do
    expect(Subscription, :occupied?, 1, true)
    expect(Subscription, :subscription_count, 1, 5)
    expect(PresenceSubscription, :user_count, 1, 3)
    expected = [occupied: true, subscription_count: 5, user_count: 3]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:channel, ["subscription_count", "user_count"]}) == {:encoded_json, :req, nil}

    assert validate JSEX
    assert validate Subscription
    assert validate PresenceSubscription
  end

  test "get_json on every single channel" do
    expect(Subscription, :all_channels, 0, ["presence-channel", "private-channel"])
    expect(PresenceSubscription, :presence_channel?, [{["presence-channel"], true},
                                                      {["private-channel"], false}])
    expect(PresenceSubscription, :user_count, 1, 3)
    expected = [channels: [{"presence-channel", user_count: 3}]]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, nil) == {:encoded_json, :req, nil}

    assert validate JSEX
    assert validate Subscription
    assert validate PresenceSubscription
  end

end
