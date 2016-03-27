defmodule Poxa.PresenceChannelTest do
  use ExUnit.Case
  import :meck
  import Poxa.PresenceChannel

  setup do
    new Poxa.registry
    on_exit fn -> unload end
    :ok
  end

  test "return unique user ids currently subscribed" do
    expect(Poxa.registry, :unique_subscriptions, ["presence-channel"], [{ :user_id, :user_info },
                                                                        { :user_id2, :user_info2 }])

    assert users("presence-channel") == [:user_id, :user_id2]

    assert validate Poxa.registry
  end

  test "return number of unique subscribed users" do
    expect(Poxa.registry, :unique_subscriptions, ["presence-channel"], [{ :user_id, :user_info },
                                                                        { :user_id2, :user_info2 }])

    assert user_count("presence-channel") == 2

    assert validate Poxa.registry
  end
end
