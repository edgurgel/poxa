defmodule Poxa.PresenceSubscriptionTest do
  use ExUnit.Case
  alias Poxa.PusherEvent
  alias Poxa.Channel
  import :meck
  import Poxa.PresenceSubscription
  alias Poxa.PresenceSubscription

  setup do
    new PusherEvent
    new :gproc
    on_exit fn -> unload end
    :ok
  end

  test "subscribe to a presence channel" do
    expect(Channel, :subscribed?, 2, false)
    expect(:gproc, :select_count, 1, 0)
    expect(:gproc, :send, 2, :sent)
    expect(:gproc, :reg, 2, :registered)
    expect(PusherEvent, :presence_member_added, 3, :event_message)
    user = {"id123", "info456"}
    other_user = {"id", "info"}
    expect(:gproc, :lookup_values, 1, [{:pid, user}, {:other_pid, other_user}])

    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == %PresenceSubscription{channel: "presence-channel", channel_data: [user, other_user]}

    assert validate Channel
    assert validate PusherEvent
    assert validate :gproc
  end

  test "subscribe to a presence channel already subscribed" do
    expect(Channel, :subscribed?, 2, true)
    user = {"id123", "info456"}
    expect(:gproc, :lookup_values, 1, [{:pid, user}])

    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == %PresenceSubscription{channel: "presence-channel", channel_data: [user]}

    assert validate Channel
    assert validate :gproc
  end

  test "subscribe to a presence channel having the same userid" do
    expect(Channel, :subscribed?, 2, false)
    expect(:gproc, :select_count, 1, 1) # true for user_id_already_on_presence_channel/2
    expect(:gproc, :reg, 2, :registered)
    expect(:gproc, :lookup_values, 1, :values)
    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == {:presence, "presence-channel", :values}
    assert validate Channel
    assert validate PusherEvent
    assert validate :gproc
  end

  test "unsubscribe to presence channel being subscribed" do
    expect(:gproc, :get_value, 1, {:userid, :userinfo})
    expect(:gproc, :send, 2, :sent)
    expect(PusherEvent, :presence_member_removed, 2, :event_message)
    assert unsubscribe!("presence-channel") == {:ok, "presence-channel"}
    assert validate PusherEvent
    assert validate :gproc
  end

  test "unsubscribe to presence channel being not subscribed" do
    expect(:gproc, :get_value, 1, nil)
    assert unsubscribe!("presence-channel") == {:ok, "presence-channel"}
    assert validate :gproc
  end

  test "check subscribed presence channels and remove having only one connection on userid" do
    expect(:gproc, :select, 1, [["presence-channel", :userid]])
    expect(:gproc, :select_count, 1, 1)
    expect(PusherEvent, :presence_member_removed, 2, :msg)
    expect(:gproc, :send, 2, :ok)
    assert check_and_remove == :ok
    assert validate PusherEvent
    assert validate :gproc
  end

  test "check subscribed presence channels and remove having more than one connection on userid" do
    expect(:gproc, :select, 1, [["presence-channel", :userid]])
    expect(:gproc, :select_count, 1, 5)
    assert check_and_remove == :ok
    assert validate PusherEvent
    assert validate :gproc
  end

  test "check subscribed presence channels and find nothing to unsubscribe" do
    expect(:gproc, :select, 1, [])
    assert check_and_remove == :ok
    assert validate :gproc
  end
end
