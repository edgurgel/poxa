Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.PresenceSubscriptionTest do
  use ExUnit.Case
  import Poxa.PresenceSubscription
  alias Poxa.PusherEvent
  alias Poxa.Subscription

  setup do
    :meck.new PusherEvent
    :meck.new Subscription
    :meck.new :gproc
  end

  teardown do
    :meck.unload PusherEvent
    :meck.unload Subscription
    :meck.unload :gproc
  end

  test "subscribe to a presence channel" do
    :meck.expect(Subscription, :subscribed?, 1, false)
    :meck.expect(:gproc, :select, 1, []) # false for user_id_already_on_presence_channel/2
    :meck.expect(:gproc, :add_shared_local_counter, 2, :ok)
    :meck.expect(:gproc, :send, 2, :sent)
    :meck.expect(:gproc, :reg, 2, :registered)
    :meck.expect(PusherEvent, :presence_member_added, 3, :event_message)
    :meck.expect(:gproc, :lookup_values, 1, :values)
    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == {:presence, "presence-channel", :values}
    assert :meck.validate Subscription
    assert :meck.validate PusherEvent
    assert :meck.validate :gproc
  end

  test "subscribe to a presence channel already subscribed" do
    :meck.expect(Subscription, :subscribed?, 1, true)
    :meck.expect(:gproc, :lookup_values, 1, :values)
    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == {:presence, "presence-channel", :values}
    assert :meck.validate Subscription
    assert :meck.validate :gproc
  end


  test "subscribe to a presence channel having the same userid" do
    :meck.expect(Subscription, :subscribed?, 1, false)
    :meck.expect(:gproc, :select, 1, [:something]) # true for user_id_already_on_presence_channel/2
    :meck.expect(:gproc, :update_shared_counter, 2, :ok)
    :meck.expect(:gproc, :reg, 2, :registered)
    :meck.expect(:gproc, :lookup_values, 1, :values)
    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == {:presence, "presence-channel", :values}
    assert :meck.validate Subscription
    assert :meck.validate PusherEvent
    assert :meck.validate :gproc
  end

  test "unsubscribe to presence channel being subscribed" do
    :meck.expect(:gproc, :get_value, 1, {:userid, :userinfo})
    :meck.expect(:gproc, :send, 2, :sent)
    :meck.expect(PusherEvent, :presence_member_removed, 2, :event_message)
    assert unsubscribe!("presence-channel") == :ok
    assert :meck.validate PusherEvent
    assert :meck.validate :gproc
  end

  test "unsubscribe to presence channel being not subscribed" do
    :meck.expect(:gproc, :get_value, 1, nil)
    assert unsubscribe!("presence-channel") == :ok
    assert :meck.validate :gproc
  end

  test "check subscribed presence channels and remove having only one connection on userid" do
    :meck.expect(:gproc, :select, 1, [["presence-channel", :userid]])
    :meck.expect(:gproc, :get_value, 2, 1)
    :meck.expect(:gproc, :unreg_shared, 1, :ok)
    :meck.expect(PusherEvent, :presence_member_removed, 2, :msg)
    :meck.expect(:gproc, :send, 2, :ok)
    assert check_and_remove == :ok
    assert :meck.validate PusherEvent
    assert :meck.validate :gproc
  end

  test "check subscribed presence channels and remove having more than one connection on userid" do
    :meck.expect(:gproc, :select, 1, [["presence-channel", :userid]])
    :meck.expect(:gproc, :get_value, 2, 5)
    :meck.expect(:gproc, :update_shared_counter, 2, :ok)
    assert check_and_remove == :ok
    assert :meck.validate PusherEvent
    assert :meck.validate :gproc
  end

  test "check subscribed presence channels and find nothing to unsubscribe" do
    :meck.expect(:gproc, :select, 1, [])
    assert check_and_remove == :ok
    assert :meck.validate :gproc
  end
end
