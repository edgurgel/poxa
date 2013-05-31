Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.SubscriptionTest do
  use ExUnit.Case
  import Poxa.Subscription
  alias Poxa.AuthSignature
  alias Poxa.PresenceSubscription

  setup do
    :meck.new PresenceSubscription
    :meck.new AuthSignature
    :meck.new :gproc
  end

  teardown do
    :meck.unload PresenceSubscription
    :meck.unload AuthSignature
    :meck.unload :gproc
  end

  test "channel is subscribed returning true" do
    :meck.expect(:gproc, :select, 1, [:something])
    assert subscribed?("channel")
    assert :meck.validate :gproc
  end

  test "channel is subscribed returning false" do
    :meck.expect(:gproc, :select, 1, [])
    refute subscribed?("channel")
    assert :meck.validate :gproc
  end

  test "subscription to a public channel" do
    :meck.expect(:gproc, :select, 1, []) # subscribed? returns false
    :meck.expect(:gproc, :reg, 1, :registered)
    assert subscribe!([{"channel", "public-channel"}], nil) == :ok
    assert :meck.validate :gproc
  end

  test "subscription to a missing channel name" do
    assert subscribe!([], nil) == :error
  end

  test "subscription to a public channel but already subscribed" do
    :meck.expect(:gproc, :select, 1, [:something]) # subscribed? returns false
    assert subscribe!([{"channel", "public-channel"}], nil) == :ok
    assert :meck.validate :gproc
  end

  test "subscription to a private channel" do
    :meck.expect(:gproc, :select, 1, []) # subscribed? returns false
    :meck.expect(:gproc, :reg, 1, :registered)
    :meck.expect(AuthSignature, :validate, 2, :ok)
    assert subscribe!([ {"channel", "private-channel"},
                                    {"auth", "signeddata"} ], "SocketId") == :ok
    assert :meck.validate AuthSignature
    assert :meck.validate :gproc
  end

  test "subscription to a private channel having a channel_data" do
    :meck.expect(:gproc, :select, 1, []) # subscribed? returns false
    :meck.expect(:gproc, :reg, 1, :registered)
    :meck.expect(AuthSignature, :validate, 2, :ok)
    assert subscribe!([ {"channel", "private-channel"},
                                    {"auth", "signeddata"},
                                    {"channel_data", "{\"user_id\" : \"id123\", \"user_info\" : \"info456\" }"} ],
                                    "SocketId") == :ok
    assert :meck.validate AuthSignature
    assert :meck.validate :gproc
  end

  test "subscription to a presence channel" do
    :meck.expect(:gproc, :select, 1, []) # subscribed? returns false
    :meck.expect(:gproc, :lookup_values, 1, :values) # subscribed? returns false
    :meck.expect(AuthSignature, :validate, 2, :ok)
    :meck.expect(PresenceSubscription, :subscribe!, 2, :ok)
    assert subscribe!([ {"channel", "presence-channel"},
                                    {"auth", "signeddata"},
                                    {"channel_data", "{\"user_id\" : \"id123\", \"user_info\" : \"info456\" "}], "SocketId") == :ok
    assert :meck.validate AuthSignature
    assert :meck.validate PresenceSubscription
    assert :meck.validate :gproc
  end

  test "subscription to a private-channel having bad authentication" do
    :meck.expect(AuthSignature, :validate, 2, :error)
    assert subscribe!([ {"channel", "private-channel"},
                                    {"auth", "signeddate"} ], "SocketId") == :error
    assert :meck.validate AuthSignature
  end

  test "subscription to a presence-channel having bad authentication" do
    :meck.expect(AuthSignature, :validate, 2, :error)
    assert subscribe!([ {"channel", "presence-channel"},
                                    {"auth", "signeddate"} ], "SocketId") == :error
    assert :meck.validate AuthSignature
  end

  test "unsubscribe channel being subscribed" do
    :meck.expect(:gproc, :select, 1, [:something]) # subscribed? returns false
    :meck.expect(:gproc, :unreg, 1, :ok)
    :meck.expect(PresenceSubscription, :presence_channel?, 1, false)
    assert unsubscribe!([{"channel", "a_channel"}]) == :ok
    assert :meck.validate :gproc
    assert :meck.validate PresenceSubscription
  end

  test "unsubscribe channel being not subscribed" do
    :meck.expect(:gproc, :select, 1, []) # subscribed? returns true
    :meck.expect(PresenceSubscription, :presence_channel?, 1, false)
    assert unsubscribe!([{"channel", "a_channel"}]) == :ok
    assert :meck.validate :gproc
    assert :meck.validate PresenceSubscription
  end

  test "unsubscribe from a presence channel" do
    :meck.expect(:gproc, :select, 1, [:something]) # subscribed? returns false
    :meck.expect(:gproc, :unreg, 1, :ok)
    :meck.expect(PresenceSubscription, :presence_channel?, 1, true)
    :meck.expect(PresenceSubscription, :unsubscribe!, 1, :ok)
    assert unsubscribe!([{"channel", "presence-channel"}]) == :ok
    assert :meck.validate PresenceSubscription
    assert :meck.validate :gproc
  end
end
