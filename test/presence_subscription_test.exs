defmodule Poxa.PresenceSubscriptionTest do
  use ExUnit.Case
  alias Poxa.PusherEvent
  alias Poxa.Channel
  import :meck
  import Poxa.PresenceSubscription
  alias Poxa.PresenceSubscription

  setup do
    new [PusherEvent, Poxa.registry, Poxa.Event]
    on_exit fn -> unload end
    :ok
  end

  test "subscribe to a presence channel" do
    expect(Channel, :member?, 2, false)
    expect(Poxa.Channel, :member?, 2, true)
    expect(Poxa.registry, :send!, 3, :sent)
    expect(Poxa.registry, :register!, 2, :registered)
    expect(PusherEvent, :presence_member_added, 3, :event_message)
    expect(Poxa.Event, :notify, [:member_added, %{channel: "presence-channel", user_id: "id123"}], :ok)

    user = {"id123", "info456"}
    other_user = {"id", "info"}
    expect(Poxa.registry, :unique_subscriptions, fn
      "presence-channel" -> [user, other_user]
    end)

    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == %PresenceSubscription{channel: "presence-channel", channel_data: [user, other_user]}

    assert validate [Channel, PusherEvent, Poxa.registry, Poxa.Event]
  end

  test "subscribe to a presence channel already subscribed" do
    expect(Channel, :member?, 2, true)
    user = {"id123", "info456"}
    expect(Poxa.registry, :unique_subscriptions, fn
      "presence-channel" -> [user]
    end)

    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == %PresenceSubscription{channel: "presence-channel", channel_data: [user]}

    assert validate [Channel, Poxa.registry]
  end

  test "subscribe to a presence channel having the same userid" do
    expect(Channel, :member?, 2, false)
    expect(Poxa.Channel, :member?, 2, true)
    expect(Poxa.registry, :register!, 2, :registered)
    user = {"id123", "info456"}
    expect(Poxa.registry, :unique_subscriptions, fn
      "presence-channel" -> [user]
    end)

    assert subscribe!("presence-channel", "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }") == %PresenceSubscription{channel: "presence-channel", channel_data: [user]}

    assert validate [Channel, PusherEvent, Poxa.registry]
  end

  test "unsubscribe to presence channel being subscribed" do
    expect(Poxa.registry, :subscription_count, 2, 1)
    expect(Poxa.registry, :fetch, 1, {:userid, :userinfo})
    expect(Poxa.registry, :send!, 3, :event_message)
    expect(PusherEvent, :presence_member_removed, 2, :event_message)
    expect(Poxa.Event, :notify, [:member_removed, %{channel: "presence-channel", user_id: :userid}], :ok)

    assert unsubscribe!("presence-channel") == {:ok, "presence-channel"}

    assert validate [PusherEvent, Poxa.registry, Poxa.Event]
  end

  test "unsubscribe to presence channel being not subscribed" do
    expect(Poxa.registry, :fetch, 1, nil)
    assert unsubscribe!("presence-channel") == {:ok, "presence-channel"}
    assert validate Poxa.registry
  end

  test "unsubscribe to presence channel having other connection with the same pid" do
    expect(Poxa.registry, :subscription_count, 2, 1)
    expect(Poxa.registry, :fetch, 1, {:userid, :userinfo})
    expect(Poxa.registry, :send!, 3, :sent)
    expect(Poxa.Event, :notify, [:member_removed, %{channel: "presence-channel", user_id: :userid}], :ok)
    expect(PusherEvent, :presence_member_removed, 2, :event_message)
    assert unsubscribe!("presence-channel") == {:ok, "presence-channel"}
    assert validate [PusherEvent, Poxa.registry, Poxa.Event]
  end

  test "check subscribed presence channels and remove having only one connection on userid" do
    expect(Poxa.registry, :subscriptions, 1, [["presence-channel", :userid]])
    expect(Poxa.registry, :subscription_count, 2, 1)
    expect(PusherEvent, :presence_member_removed, 2, :msg)
    expect(Poxa.registry, :send!, 3, :ok)
    expect(Poxa.Event, :notify, [:member_removed, %{channel: "presence-channel", user_id: :userid}], :ok)

    assert check_and_remove == 1

    assert validate [PusherEvent, Poxa.registry, Poxa.Event]
  end

  test "check subscribed presence channels and remove having more than one connection on userid" do
    expect(Poxa.registry, :subscriptions, 1, [["presence-channel", :userid]])
    expect(Poxa.registry, :subscription_count, 2, 5)
    assert check_and_remove == 0
    assert validate [PusherEvent, Poxa.registry]
  end

  test "check subscribed presence channels and find nothing to unsubscribe" do
    expect(Poxa.registry, :subscriptions, 1, [])
    assert check_and_remove == 0
    assert validate Poxa.registry
  end
end
