Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.PresenceSubscriptionTest do
  use ExUnit.Case
  alias Poxa.PusherEvent
  alias Poxa.Subscription
  import :meck
  import Poxa.PresenceSubscription

  setup do
    new PusherEvent
    new Subscription
    new :gproc
  end

  teardown do
    unload PusherEvent
    unload Subscription
    unload :gproc
  end

  test "subscribe to a presence channel" do
    expect(Subscription, :subscribed?, 1, false)
    expect(:gproc, :select_count, 1, 0)
    expect(:gproc, :send, 2, :sent)
    expect(:gproc, :mreg, 3, :registered)
    expect(PusherEvent, :presence_member_added, 3, :event_message)
    expect(:gproc, :lookup_values, 1, :values)
    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == {:presence, "presence-channel", :values}
    assert validate Subscription
    assert validate PusherEvent
    assert validate :gproc
  end

  test "subscribe to a presence channel already subscribed" do
    expect(Subscription, :subscribed?, 1, true)
    expect(:gproc, :lookup_values, 1, :values)
    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == {:presence, "presence-channel", :values}
    assert validate Subscription
    assert validate :gproc
  end


  test "subscribe to a presence channel having the same userid" do
    expect(Subscription, :subscribed?, 1, false)
    expect(:gproc, :select_count, 1, 1) # true for user_id_already_on_presence_channel/2
    expect(:gproc, :update_shared_counter, 2, :ok)
    expect(:gproc, :mreg, 3, :registered)
    expect(:gproc, :lookup_values, 1, :values)
    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == {:presence, "presence-channel", :values}
    assert validate Subscription
    assert validate PusherEvent
    assert validate :gproc
  end

  test "unsubscribe to presence channel being subscribed" do
    expect(:gproc, :get_value, 1, {:userid, :userinfo})
    expect(:gproc, :send, 2, :sent)
    expect(PusherEvent, :presence_member_removed, 2, :event_message)
    assert unsubscribe!("presence-channel") == :ok
    assert validate PusherEvent
    assert validate :gproc
  end

  test "unsubscribe to presence channel being not subscribed" do
    expect(:gproc, :get_value, 1, nil)
    assert unsubscribe!("presence-channel") == :ok
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

  test "return unique user ids currently subscribed" do
    expect(:gproc, :select, 1, [ {:user_id, :user_info},
                                 {:user_id, :user_info},
                                 {:user_id2, :user_info2} ])
    assert users("presence-channel") == [:user_id, :user_id2]
    assert validate :gproc
  end

  test "return number of unique subscribed users" do
    expect(:gproc, :select, 1, [ {:user_id, :user_info},
                                 {:user_id, :user_info},
                                 {:user_id2, :user_info2} ])
    assert user_count("presence-channel") == 2
    assert validate :gproc
  end
end
