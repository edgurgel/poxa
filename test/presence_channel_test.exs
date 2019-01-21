defmodule Poxa.PresenceChannelTest do
  use ExUnit.Case, async: true
  import Mimic
  import Poxa.PresenceChannel

  setup :verify_on_exit!

  setup do
    stub(Poxa.registry)
    :ok
  end

  test "return unique user ids currently subscribed" do
    expect(Poxa.registry, :unique_subscriptions, fn "presence-channel" ->
      [{:user_id, :user_info},{:user_id2, :user_info2}]
    end)

    assert users("presence-channel") == [:user_id, :user_id2]
  end

  test "return number of unique subscribed users" do
    expect(Poxa.registry, :unique_subscriptions, fn "presence-channel" ->
      [{:user_id, :user_info},{:user_id2, :user_info2}]
    end)

    assert user_count("presence-channel") == 2
  end
end
