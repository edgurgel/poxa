defmodule Poxa.SubscriptionTest do
  use ExUnit.Case
  alias Poxa.AuthSignature
  alias Poxa.PresenceSubscription
  import :meck
  import Poxa.Subscription

  defp spawn_registered_process(channel) do
    parent = self
    spawn_link fn ->
      register_to_channel(channel)
      send parent, :registered
      receive do
        _ -> :wait
      end
    end
    receive do
      :registered -> :ok
    end
  end

  defp register_to_channel(channel) do
    :gproc.reg({:p, :l, {:pusher, channel}})
  end

  setup do
    new PresenceSubscription
    new AuthSignature
    on_exit fn -> unload end
    :ok
  end

  test "subscription to a public channel" do
    expect(:gproc, :select, 1, []) # subscribed? returns false
    expect(:gproc, :reg, 1, :registered)
    assert subscribe!(%{"channel" => "public-channel"}, nil) == {:ok, "public-channel"}
    assert validate :gproc
  end

  test "subscription to a missing channel name" do
    assert subscribe!(%{}, nil) == :error
  end

  test "subscription to a public channel but already subscribed" do
    expect(:gproc, :select, 1, [:something]) # subscribed? returns false
    assert subscribe!(%{"channel" => "public-channel"}, nil) == {:ok, "public-channel"}
    assert validate :gproc
  end

  test "subscription to a private channel" do
    expect(:gproc, :select, 1, []) # subscribed? returns false
    expect(:gproc, :reg, 1, :registered)
    expect(AuthSignature, :validate, 2, :ok)
    assert subscribe!(%{"channel" => "private-channel",
                        "auth" => "signeddata" }, "SocketId") == {:ok, "private-channel"}
    assert validate AuthSignature
    assert validate :gproc
  end

  test "subscription to a private channel having a channel_data" do
    expect(:gproc, :select, 1, []) # subscribed? returns false
    expect(:gproc, :reg, 1, :registered)
    expect(AuthSignature, :validate, 2, :ok)
    assert subscribe!(%{"channel" => "private-channel",
                        "auth" => "signeddata",
                        "channel_data" => "{\"user_id\" : \"id123\", \"user_info\" : \"info456\"}"}, "SocketId") == {:ok, "private-channel"}
    assert validate AuthSignature
    assert validate :gproc
  end

  test "subscription to a presence channel" do
    expect(:gproc, :select, 1, []) # subscribed? returns false
    expect(:gproc, :lookup_values, 1, :values) # subscribed? returns false
    expect(AuthSignature, :validate, 2, :ok)
    expect(PresenceSubscription, :subscribe!, 2, :ok)

    assert subscribe!(%{"channel" => "presence-channel",
                        "auth" => "signeddata",
                        "channel_data" => "{\"user_id\" : \"id123\", \"user_info\" : \"info456\""}, "SocketId") == :ok

    assert validate AuthSignature
    assert validate PresenceSubscription
    assert validate :gproc
  end

  test "subscription to a private-channel having bad authentication" do
    expect(AuthSignature, :validate, 2, :error)

    assert subscribe!(%{"channel" => "private-channel",
                        "auth" => "signeddate"}, "SocketId") == :error

    assert validate AuthSignature
  end

  test "subscription to a presence-channel having bad authentication" do
    expect(AuthSignature, :validate, 2, :error)

    assert subscribe!(%{"channel" => "presence-channel",
                        "auth" => "signeddate"}, "SocketId") == :error

    assert validate AuthSignature
  end

  test "unsubscribe channel being subscribed" do
    expect(:gproc, :select, 1, [:something]) # subscribed? returns false
    expect(:gproc, :unreg, 1, :ok)
    expect(PresenceSubscription, :presence_channel?, 1, false)

    assert unsubscribe!(%{"channel" => "a_channel"}) == {:ok, "a_channel"}

    assert validate :gproc
    assert validate PresenceSubscription
  end

  test "unsubscribe channel being not subscribed" do
    expect(:gproc, :select, 1, []) # subscribed? returns true
    expect(PresenceSubscription, :presence_channel?, 1, false)

    assert unsubscribe!(%{"channel" => "a_channel"}) == {:ok, "a_channel"}

    assert validate :gproc
    assert validate PresenceSubscription
  end

  test "unsubscribe from a presence channel" do
    expect(:gproc, :select, 1, [:something]) # subscribed? returns false
    expect(:gproc, :unreg, 1, :ok)
    expect(PresenceSubscription, :presence_channel?, 1, true)
    expect(PresenceSubscription, :unsubscribe!, 1, {:ok, "presence-channel"})

    assert unsubscribe!(%{"channel" => "presence-channel"}) == {:ok, "presence-channel"}

    assert validate PresenceSubscription
    assert validate :gproc
  end

  test "channel is subscribed? returning true" do
    register_to_channel("channel")

    assert subscribed?("channel")
  end

  test "channel is subscribed returning false" do
    refute subscribed?("channel")
  end

  test "subscription_count on channel" do
    register_to_channel("channel")
    spawn_registered_process("channel")

    assert subscription_count("channel") == 2
  end

  test "occupied? returns false for empty channel" do
    refute occupied?("a channel")
  end

  test "occupied? returns true for populated channel" do
    register_to_channel("a channel")

    assert occupied?("a channel")
  end

  test "list all channels" do
    register_to_channel("channel1")
    register_to_channel("channel2")
    spawn_registered_process("channel3")

    assert all_channels == ["channel1", "channel2", "channel3"]
  end

  test "list channels of a pid" do
    register_to_channel("channel1")
    register_to_channel("channel2")
    register_to_channel("channel3")

    assert channels(self) == ["channel1", "channel2", "channel3"]
  end
end
