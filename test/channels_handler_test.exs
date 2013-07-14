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

  test "get_json on a specific channel" do
    expect(:cowboy_req, :binding, 3, {:channel, :req})
    expect(Subscription, :subscription_count, 1, 5)
    expected = [occupied: true, subscription_count: 5]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, :state) == {:encoded_json, :req, :state}

    assert validate JSEX
    assert validate Subscription
    assert validate :cowboy_req
  end

  test "get_json on every single channel" do
    expect(:cowboy_req, :binding, 3, {nil, :req})
    expect(Subscription, :all_channels, 0, ["presence-channel", "private-channel"])
    expect(PresenceSubscription, :presence_channel?, [{["presence-channel"], true},
                                                      {["private-channel"], false}])
    expect(PresenceSubscription, :user_count, 1, 3)
    expected = [channels: [{"presence-channel", user_count: 3}]]
    expect(JSEX, :encode!, [{[expected], :encoded_json}])

    assert get_json(:req, :state) == {:encoded_json, :req, :state}

    assert validate JSEX
    assert validate Subscription
    assert validate PresenceSubscription
    assert validate :cowboy_req
  end

end
