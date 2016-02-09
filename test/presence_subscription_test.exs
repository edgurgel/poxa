defmodule Poxa.PresenceSubscriptionTest do
  use ExUnit.Case
  alias Poxa.PusherEvent
  alias Poxa.Channel
  alias Poxa.Registry
  import :meck
  import Poxa.PresenceSubscription
  alias Poxa.PresenceSubscription

  setup do
    new PusherEvent
    new Registry
    on_exit fn -> unload end
    :ok
  end

  test "subscribe to a presence channel" do
    expect(Channel, :subscribed?, 2, false)
    expect(Registry, :in_presence_channel?, 2, 0)
    expect(Registry, :send_event, 2, :sent)
    expect(Registry, :subscribe, 2, :registered)
    expect(PusherEvent, :presence_member_added, 3, :event_message)
    user = {"id123", "info456"}
    other_user = {"id", "info"}
    expect(Registry, :channel_data, 1, [user, other_user])

    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == %PresenceSubscription{channel: "presence-channel", channel_data: [user, other_user]}

    assert validate Channel
    assert validate PusherEvent
    assert validate Registry
  end

  test "subscribe to a presence channel already subscribed" do
    expect(Channel, :subscribed?, 2, true)
    user = {"id123", "info456"}
    expect(Registry, :channel_data, 1, [user])

    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == %PresenceSubscription{channel: "presence-channel", channel_data: [user]}

    assert validate Channel
    assert validate Registry
  end

  test "subscribe to a presence channel having the same userid" do
    expect(Channel, :subscribed?, 2, false)
    expect(Registry, :in_presence_channel?, 2, true) # true for user_id_already_on_presence_channel/2
    expect(Registry, :subscribe, 2, :registered)
    user = {"id123", "info456"}
    expect(Registry, :channel_data, 1, [user])

    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == %PresenceSubscription{channel: "presence-channel", channel_data: [user]}

    assert validate Channel
    assert validate PusherEvent
    assert validate Registry
  end

  test "unsubscribe to presence channel being subscribed" do
    expect(Registry, :connection_count, 2, 1)
    expect(Registry, :fetch_subscription, 1, {:userid, :userinfo})
    expect(Registry, :send_event, 2, :sent)
    expect(PusherEvent, :presence_member_removed, 2, :event_message)
    assert unsubscribe!("presence-channel") == {:ok, "presence-channel"}
    assert validate PusherEvent
    assert validate Registry
  end

  test "unsubscribe to presence channel being not subscribed" do
    expect(Registry, :connection_count, 2, 0)
    expect(Registry, :fetch_subscription, 1, nil)
    assert unsubscribe!("presence-channel") == {:ok, "presence-channel"}
    assert validate Registry
  end

  test "unsubscribe to presence channel having other connection with the same pid" do
    expect(Registry, :connection_count, 2, 2)
    expect(Registry, :fetch_subscription, 1, {:userid, :userinfo})
    expect(Registry, :send_event, 2, :sent)
    expect(PusherEvent, :presence_member_removed, 2, :event_message)
    assert unsubscribe!("presence-channel") == {:ok, "presence-channel"}
    assert validate PusherEvent
    assert validate Registry
  end

  test "check subscribed presence channels and remove having only one connection on userid" do
    expect(Registry, :subscriptions, 0, [["presence-channel", :userid]])
    expect(Registry, :connection_count, 2, 1)
    expect(PusherEvent, :presence_member_removed, 2, :msg)
    expect(Registry, :send_event, 2, :ok)
    assert check_and_remove == :ok
    assert validate PusherEvent
    assert validate Registry
  end

  test "check subscribed presence channels and remove having more than one connection on userid" do
    expect(Registry, :subscriptions, 0, [["presence-channel", :userid]])
    expect(Registry, :connection_count, 2, 5)
    assert check_and_remove == :ok
    assert validate PusherEvent
    assert validate Registry
  end

  test "check subscribed presence channels and find nothing to unsubscribe" do
    expect(Registry, :subscriptions, 0, [])
    assert check_and_remove == :ok
    assert validate Registry
  end
end
