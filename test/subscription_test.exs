defmodule Poxa.SubscriptionTest do
  use ExUnit.Case
  alias Poxa.AuthSignature
  alias Poxa.PresenceSubscription
  alias Poxa.Channel
  alias Poxa.PusherEvent
  import :meck
  import Poxa.Subscription

  setup do
    new PresenceSubscription
    new AuthSignature
    new PusherEvent
    new Channel, [:passthrough]
    new Poxa.registry
    on_exit fn -> unload end
    :ok
  end

  test "subscription to a public channel" do
    expect(Channel, :member?, 2, false)
    expect(Poxa.registry, :register!, 1, :registered)
    assert subscribe!(%{"channel" => "public-channel"}, nil) == {:ok, "public-channel"}
    assert validate Poxa.registry
  end

  test "subscription to a missing channel name" do
    expect(PusherEvent, :pusher_error, 1, :error_message)

    assert subscribe!(%{}, nil) == {:error, :error_message}

    assert validate PusherEvent
  end

  test "subscription to a public channel but already subscribed" do
    expect(Channel, :member?, 2, true)
    assert subscribe!(%{"channel" => "public-channel"}, nil) == {:ok, "public-channel"}
  end

  test "subscription to a private channel" do
    expect(Channel, :member?, 2, false)
    expect(Poxa.registry, :register!, 1, :registered)
    expect(AuthSignature, :valid?, 2, true)
    assert subscribe!(%{"channel" => "private-channel",
                        "auth" => "signeddata" }, "SocketId") == {:ok, "private-channel"}
    assert validate [AuthSignature, Poxa.registry]
  end

  test "subscription to a private channel having a channel_data" do
    expect(Channel, :member?, 2, false)
    expect(Poxa.registry, :register!, 1, :registered)
    expect(AuthSignature, :valid?, 2, true)
    assert subscribe!(%{"channel" => "private-channel",
                        "auth" => "signeddata",
                        "channel_data" => "{\"user_id\" : \"id123\", \"user_info\" : \"info456\"}"}, "SocketId") == {:ok, "private-channel"}
    assert validate [AuthSignature, Poxa.registry]
  end

  test "subscription to a presence channel" do
    expect(Channel, :member?, 2, false)
    expect(AuthSignature, :valid?, 2, true)
    expect(PresenceSubscription, :subscribe!, 2, :ok)

    assert subscribe!(%{"channel" => "presence-channel",
                        "auth" => "signeddata",
                        "channel_data" => "{\"user_id\" : \"id123\", \"user_info\" : \"info456\""}, "SocketId") == :ok

    assert validate AuthSignature
    assert validate PresenceSubscription
  end

  test "subscription to a private-channel having bad authentication" do
    expect(AuthSignature, :valid?, 2, false)
    expect(PusherEvent, :pusher_error, 1, :error_message)

    assert subscribe!(%{"channel" => "private-channel",
                        "auth" => "signeddate"}, "SocketId") == {:error, :error_message}

    assert validate AuthSignature
    assert validate PusherEvent
  end

  test "subscription to a presence-channel having bad authentication" do
    expect(AuthSignature, :valid?, 2, false)
    expect(PusherEvent, :pusher_error, 1, :error_message)

    assert subscribe!(%{"channel" => "presence-channel",
                        "auth" => "signeddate"}, "SocketId") == {:error, :error_message}

    assert validate AuthSignature
    assert validate PusherEvent
  end

  test "unsubscribe channel being subscribed" do
    expect(Channel, :member?, 2, true)
    expect(Channel, :presence?, 1, false)
    expect(Poxa.registry, :unregister!, 1, :ok)

    assert unsubscribe!(%{"channel" => "a_channel"}) == {:ok, "a_channel"}

    assert validate Poxa.registry
  end

  test "unsubscribe channel being not subscribed" do
    expect(Channel, :member?, 2, false)
    expect(Channel, :presence?, 1, false)

    assert unsubscribe!(%{"channel" => "a_channel"}) == {:ok, "a_channel"}
  end

  test "unsubscribe from a presence channel" do
    expect(Channel, :member?, 2, false)
    expect(Channel, :presence?, 1, true)
    expect(PresenceSubscription, :unsubscribe!, 1, {:ok, "presence-channel"})

    assert unsubscribe!(%{"channel" => "presence-channel"}) == {:ok, "presence-channel"}

    assert validate PresenceSubscription
  end
end
