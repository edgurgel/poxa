defmodule Poxa.PresenceSubscriptionTest do
  use ExUnit.Case, async: true
  alias Poxa.PusherEvent
  alias Poxa.Channel
  use Mimic
  import Poxa.PresenceSubscription
  alias Poxa.PresenceSubscription

  setup do
    stub(PusherEvent)
    stub(Poxa.Event)
    stub(Poxa.registry())
    stub(Channel)
    :ok
  end

  test "subscribe to a presence channel" do
    pid = self()
    expect(Channel, :member?, fn "presence-channel", ^pid -> false end)
    expect(Channel, :member?, fn "presence-channel", "id123" -> false end)

    expect(Poxa.registry(), :register!, fn "presence-channel", {"id123", "info456"} ->
      :registered
    end)

    expect(Poxa.Event, :notify, fn :member_added,
                                   %{channel: "presence-channel", user_id: "id123"} ->
      :ok
    end)

    expect(PusherEvent, :presence_member_added, fn "presence-channel", "id123", "info456" ->
      :event_message
    end)

    expect(Poxa.registry(), :send!, fn :event_message, "presence-channel", ^pid -> :sent end)

    user = {"id123", "info456"}
    other_user = {"id", "info"}

    expect(Poxa.registry(), :unique_subscriptions, fn
      "presence-channel" -> [user, other_user]
    end)

    assert subscribe!(
             "presence-channel",
             "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }"
           ) == %PresenceSubscription{
             channel: "presence-channel",
             channel_data: [user, other_user]
           }
  end

  test "subscribe to a presence channel already subscribed" do
    pid = self()
    expect(Channel, :member?, fn "presence-channel", ^pid -> true end)
    user = {"id123", "info456"}

    expect(Poxa.registry(), :unique_subscriptions, fn
      "presence-channel" -> [user]
    end)

    assert subscribe!(
             "presence-channel",
             "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }"
           ) == %PresenceSubscription{channel: "presence-channel", channel_data: [user]}
  end

  test "subscribe to a presence channel having the same userid" do
    pid = self()
    expect(Channel, :member?, fn "presence-channel", ^pid -> false end)
    expect(Channel, :member?, fn "presence-channel", "id123" -> true end)

    expect(Poxa.registry(), :register!, fn "presence-channel", {"id123", "info456"} ->
      :registered
    end)

    user = {"id123", "info456"}

    expect(Poxa.registry(), :unique_subscriptions, fn
      "presence-channel" -> [user]
    end)

    assert subscribe!(
             "presence-channel",
             "{ \"user_id\" : \"id123\", \"user_info\" : \"info456\" }"
           ) == %PresenceSubscription{channel: "presence-channel", channel_data: [user]}
  end

  test "unsubscribe to presence channel being subscribed" do
    pid = self()
    expect(Poxa.registry(), :fetch, fn "presence-channel" -> {:userid, :userinfo} end)
    expect(Poxa.registry(), :subscription_count, fn "presence-channel", :userid -> 1 end)

    expect(Poxa.Event, :notify, fn :member_removed,
                                   %{channel: "presence-channel", user_id: :userid} ->
      :ok
    end)

    expect(PusherEvent, :presence_member_removed, fn "presence-channel", :userid ->
      :event_message
    end)

    expect(Poxa.registry(), :send!, fn :event_message, "presence-channel", ^pid ->
      :event_message
    end)

    assert unsubscribe!("presence-channel") == {:ok, "presence-channel"}
  end

  # test "unsubscribe to presence channel being not subscribed" do
  # expect(Poxa.registry, :fetch, 1, nil)
  # assert unsubscribe!("presence-channel") == {:ok, "presence-channel"}
  # end

  # test "unsubscribe to presence channel having other connection with the same pid" do
  # expect(Poxa.registry, :subscription_count, 2, 1)
  # expect(Poxa.registry, :fetch, 1, {:userid, :userinfo})
  # expect(Poxa.registry, :send!, 3, :sent)
  # expect(Poxa.Event, :notify, [:member_removed, %{channel: "presence-channel", user_id: :userid}], :ok)
  # expect(PusherEvent, :presence_member_removed, 2, :event_message)
  # assert unsubscribe!("presence-channel") == {:ok, "presence-channel"}
  # end

  # test "check subscribed presence channels and remove having only one connection on userid" do
  # expect(Poxa.registry, :subscriptions, 1, [["presence-channel", :userid]])
  # expect(Poxa.registry, :subscription_count, 2, 1)
  # expect(PusherEvent, :presence_member_removed, 2, :msg)
  # expect(Poxa.registry, :send!, 3, :ok)
  # expect(Poxa.Event, :notify, [:member_removed, %{channel: "presence-channel", user_id: :userid}], :ok)

  # assert check_and_remove() == 1
  # end

  # test "check subscribed presence channels and remove having more than one connection on userid" do
  # expect(Poxa.registry, :subscriptions, 1, [["presence-channel", :userid]])
  # expect(Poxa.registry, :subscription_count, 2, 5)
  # assert check_and_remove() == 0
  # end

  # test "check subscribed presence channels and find nothing to unsubscribe" do
  # expect(Poxa.registry, :subscriptions, 1, [])
  # assert check_and_remove() == 0
  # end
end
