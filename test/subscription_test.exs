defmodule Poxa.SubscriptionTest do
  use ExUnit.Case
  alias Poxa.AuthSignature
  alias Poxa.PresenceSubscription
  import :meck
  import Poxa.Subscription

  setup do
    new PresenceSubscription
    new AuthSignature
    new :gproc
  end

  teardown do
    unload PresenceSubscription
    unload AuthSignature
    unload :gproc
  end

  test "channel is subscribed returning true" do
    expect(:gproc, :select, 1, [:something])
    assert subscribed?("channel")
    assert validate :gproc
  end

  test "channel is subscribed returning false" do
    expect(:gproc, :select, 1, [])
    refute subscribed?("channel")
    assert validate :gproc
  end

  test "subscription to a public channel" do
    expect(:gproc, :select, 1, []) # subscribed? returns false
    expect(:gproc, :reg, 1, :registered)
    assert subscribe!([{"channel", "public-channel"}], nil) == {:ok, "public-channel"}
    assert validate :gproc
  end

  test "subscription to a missing channel name" do
    assert subscribe!([], nil) == :error
  end

  test "subscription to a public channel but already subscribed" do
    expect(:gproc, :select, 1, [:something]) # subscribed? returns false
    assert subscribe!([{"channel", "public-channel"}], nil) == {:ok, "public-channel"}
    assert validate :gproc
  end

  test "subscription to a private channel" do
    expect(:gproc, :select, 1, []) # subscribed? returns false
    expect(:gproc, :reg, 1, :registered)
    expect(AuthSignature, :validate, 2, :ok)
    assert subscribe!([ {"channel", "private-channel"},
                                    {"auth", "signeddata"} ], "SocketId") == {:ok, "private-channel"}
    assert validate AuthSignature
    assert validate :gproc
  end

  test "subscription to a private channel having a channel_data" do
    expect(:gproc, :select, 1, []) # subscribed? returns false
    expect(:gproc, :reg, 1, :registered)
    expect(AuthSignature, :validate, 2, :ok)
    assert subscribe!([ {"channel", "private-channel"},
                                    {"auth", "signeddata"},
                                    {"channel_data", "{\"user_id\" : \"id123\", \"user_info\" : \"info456\" }"} ],
                                    "SocketId") == {:ok, "private-channel"}
    assert validate AuthSignature
    assert validate :gproc
  end

  test "subscription to a presence channel" do
    expect(:gproc, :select, 1, []) # subscribed? returns false
    expect(:gproc, :lookup_values, 1, :values) # subscribed? returns false
    expect(AuthSignature, :validate, 2, :ok)
    expect(PresenceSubscription, :subscribe!, 2, :ok)
    assert subscribe!([ {"channel", "presence-channel"},
                                    {"auth", "signeddata"},
                                    {"channel_data", "{\"user_id\" : \"id123\", \"user_info\" : \"info456\" "}], "SocketId") == :ok
    assert validate AuthSignature
    assert validate PresenceSubscription
    assert validate :gproc
  end

  test "subscription to a private-channel having bad authentication" do
    expect(AuthSignature, :validate, 2, :error)
    assert subscribe!([ {"channel", "private-channel"},
                                    {"auth", "signeddate"} ], "SocketId") == :error
    assert validate AuthSignature
  end

  test "subscription to a presence-channel having bad authentication" do
    expect(AuthSignature, :validate, 2, :error)
    assert subscribe!([ {"channel", "presence-channel"},
                                    {"auth", "signeddate"} ], "SocketId") == :error
    assert validate AuthSignature
  end

  test "unsubscribe channel being subscribed" do
    expect(:gproc, :select, 1, [:something]) # subscribed? returns false
    expect(:gproc, :unreg, 1, :ok)
    expect(PresenceSubscription, :presence_channel?, 1, false)
    assert unsubscribe!([{"channel", "a_channel"}]) == :ok
    assert validate :gproc
    assert validate PresenceSubscription
  end

  test "unsubscribe channel being not subscribed" do
    expect(:gproc, :select, 1, []) # subscribed? returns true
    expect(PresenceSubscription, :presence_channel?, 1, false)
    assert unsubscribe!([{"channel", "a_channel"}]) == :ok
    assert validate :gproc
    assert validate PresenceSubscription
  end

  test "unsubscribe from a presence channel" do
    expect(:gproc, :select, 1, [:something]) # subscribed? returns false
    expect(:gproc, :unreg, 1, :ok)
    expect(PresenceSubscription, :presence_channel?, 1, true)
    expect(PresenceSubscription, :unsubscribe!, 1, :ok)
    assert unsubscribe!([{"channel", "presence-channel"}]) == :ok
    assert validate PresenceSubscription
    assert validate :gproc
  end

  test "list all channels" do
    expect(:gproc, :select, 1, ["channel1", "channel2", "channel3", "channel1"])

    assert all_channels == ["channel1", "channel2", "channel3"]

    assert validate :gproc
  end

  test "list channels of a pid" do
    expect(:gproc, :select, 1, ["channel1", "channel2", "channel3", "channel1"])

    assert channels(self) == ["channel1", "channel2", "channel3"]

    assert validate :gproc
  end
end
