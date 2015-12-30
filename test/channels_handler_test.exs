defmodule Poxa.ChannelsHandlerTest do
  use ExUnit.Case
  alias Poxa.Channel
  alias Poxa.PresenceChannel
  import :meck
  import Poxa.ChannelsHandler

  setup do
    new JSX
    new :cowboy_req
    on_exit fn -> unload end
    :ok
  end

  test "malformed_request on multiple channels with no attributes" do
    expect(:cowboy_req, :qs_val, 3, seq([{"", :req}, {nil, :req}]))
    expect(:cowboy_req, :binding, 3, {nil, :req})
    expect(:cowboy_req, :binding, 2, {"app_id", :req})

    assert malformed_request(:req, :state) == {false, :req, {:all, "app_id", nil, []}}

    assert validate :cowboy_req
  end

  test "malformed_request on multiple channels with valid attributes" do
    expect(:cowboy_req, :qs_val, 3, seq([{"subscription_count", :req}, {nil, :req}]))
    expect(:cowboy_req, :binding, 3, {nil, :req})
    expect(:cowboy_req, :binding, 2, {"app_id", :req})

    assert malformed_request(:req, :state) == {false, :req, {:all, "app_id", nil, ["subscription_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on multiple channels with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, seq([{"user_count", :req}, {nil, :req}]))
    expect(:cowboy_req, :binding, 3, {nil, :req})
    expect(:cowboy_req, :binding, 2, {"app_id", :req})

    assert malformed_request(:req, :state) == {true, :req, {:all, "app_id", nil, ["user_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on multiple channels with filter" do
    expect(:cowboy_req, :qs_val, 3, seq([{"", :req}, {"poxa-", :req}]))
    expect(:cowboy_req, :binding, 3, {nil, :req})
    expect(:cowboy_req, :binding, 2, {"app_id", :req})

    assert malformed_request(:req, :state) == {false, :req, {:all, "app_id", "poxa-", []}}

    assert validate :cowboy_req
  end

  test "malformed_request on multiple channels with presence filter and user_count attribute" do
    expect(:cowboy_req, :qs_val, 3, seq([{"user_count", :req}, {"presence-", :req}]))
    expect(:cowboy_req, :binding, 3, {nil, :req})
    expect(:cowboy_req, :binding, 2, {"app_id", :req})

    assert malformed_request(:req, :state) == {false, :req, {:all, "app_id", "presence-", ["user_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"subscription_count,message_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})
    expect(:cowboy_req, :binding, 2, {"app_id", :req})

    assert malformed_request(:req, :state) == {true, :req, {:one, "app_id", "channel", ["subscription_count", "message_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single channel with invalid attribute" do
    expect(:cowboy_req, :qs_val, 3, {"message_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})
    expect(:cowboy_req, :binding, 2, {"app_id", :req})

    assert malformed_request(:req, :state) == {true, :req, {:one, "app_id", "channel", ["message_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single channel with valid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"subscription_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})
    expect(:cowboy_req, :binding, 2, {"app_id", :req})

    assert malformed_request(:req, :state) == {false, :req, {:one, "app_id", "channel", ["subscription_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single non presence-channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"user_count", :req})
    expect(:cowboy_req, :binding, 3, {"channel", :req})
    expect(:cowboy_req, :binding, 2, {"app_id", :req})

    assert malformed_request(:req, :state) == {true, :req, {:one, "app_id", "channel", ["user_count"]}}

    assert validate :cowboy_req
  end

  test "malformed_request on single presence-channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, 3, {"user_count,subscription_count", :req})
    expect(:cowboy_req, :binding, 3, {"presence-channel", :req})
    expect(:cowboy_req, :binding, 2, {"app_id", :req})

    assert malformed_request(:req, :state) == {false, :req, {:one, "app_id", "presence-channel", ["user_count", "subscription_count"]}}

    assert validate :cowboy_req
  end

  test "get_json on a specific channel with subscription_count attribute" do
    expect(Channel, :occupied?, 2, true)
    expect(Channel, :subscription_count, 2, 5)
    expected = [occupied: true, subscription_count: 5]
    expect(JSX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:one, "app_id", :channel, ["subscription_count"]}) == {:encoded_json, :req, nil}

    assert validate JSX
    assert validate Channel
  end

  test "get_json on a specific channel with user_count attribute" do
    expect(Channel, :occupied?, 2, true)
    expect(PresenceChannel, :user_count, 2, 3)
    expected = [occupied: true, user_count: 3]
    expect(JSX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:one, "app_id", :channel, ["user_count"]}) == {:encoded_json, :req, nil}

    assert validate JSX
    assert validate Channel
    assert validate PresenceChannel
  end

  test "get_json on a specific channel with user_count and subscription_count attributes" do
    expect(Channel, :occupied?, 2, true)
    expect(Channel, :subscription_count, 2, 5)
    expect(PresenceChannel, :user_count, 2, 3)
    expected = [occupied: true, subscription_count: 5, user_count: 3]
    expect(JSX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:one, "app_id", :channel, ["subscription_count", "user_count"]}) == {:encoded_json, :req, nil}

    assert validate JSX
    assert validate Channel
    assert validate PresenceChannel
  end

  test "get_json on every single channel" do
    expect(:cowboy_req, :qs_val, 3, {nil, :req})
    expect(Channel, :all, 1, ["presence-channel", "private-channel"])
    expect(Channel, :presence?, 1, true)
    expect(PresenceChannel, :user_count, 2, 3)
    expected = [channels: [{"presence-channel", user_count: 3}]]
    expect(JSX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:all, "app_id", nil, ["user_count"]}) == {:encoded_json, :req, nil}

    assert validate JSX
    assert validate Channel
    assert validate PresenceChannel
  end

  test "get_json on every single channel with filter" do
    expect(Channel, :all, 1, ["presence-channel", "poxa-channel"])
    expect(Channel, :matches?, 2, seq([false, true]))
    expected = [channels: [{"poxa-channel", []}]]
    expect(JSX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, {:all, "app_id", "poxa-", []}) == {:encoded_json, :req, nil}

    assert validate JSX
    assert validate Channel
  end
end
