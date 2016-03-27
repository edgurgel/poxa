defmodule Poxa.ChannelTest do
  use ExUnit.Case
  import Poxa.Channel
  import :meck
  doctest Poxa.Channel

  setup do
    new Poxa.registry
    on_exit fn -> unload end
    :ok
  end

  test "occupied? returns false for empty channel" do
    expect(Poxa.registry, :subscription_count, ["channel", :_], 0)

    refute occupied?("channel")

    assert validate Poxa.registry
  end

  test "occupied? returns true for populated channel" do
    expect(Poxa.registry, :subscription_count, ["channel", :_], 42)

    assert occupied?("channel")

    assert validate Poxa.registry
  end

  test "list all channels" do
    channels = ~w(channel1 channel2 channel3)
    expect(Poxa.registry, :channels, [:_], ~w(channel1 channel2 channel3))

    assert all == channels

    assert validate Poxa.registry
  end

  test "list channels of a pid" do
    channels = ~w(channel1 channel2 channel3)
    expect(Poxa.registry, :channels, [self], ~w(channel1 channel2 channel3))

    assert all(self) == channels

    assert validate Poxa.registry
  end

  test "channel is member? returning true" do
    expect(Poxa.registry, :subscription_count, ["channel", self], 1)

    assert member?("channel", self)

    assert validate Poxa.registry
  end

  test "channel is subscribed returning false" do
    expect(Poxa.registry, :subscription_count, ["channel", self], 0)

    refute member?("channel", self)

    assert validate Poxa.registry
  end

  test "subscription_count on channel" do
    expect(Poxa.registry, :subscription_count, ["channel", :_], 2)

    assert subscription_count("channel") == 2

    assert validate Poxa.registry
  end

  test "valid? return true for valid characters" do
    assert valid?("some_channel")
    assert valid?("some-channel")
    assert valid?("some=channel")
    assert valid?("some@channel")
    assert valid?("some,channel")
    assert valid?("some.channel")
    assert valid?("some;channel")
    assert valid?("foo-bar_1234@=,.;")
  end

  test "valid? return false for invalid characters" do
    refute valid?("some`channel")
    refute valid?("some~channel")
    refute valid?("some!channel")
    refute valid?("some#channel")
    refute valid?("some$channel")
    refute valid?("some%channel")
    refute valid?("some^channel")
    refute valid?("some&channel")
    refute valid?("some*channel")
    refute valid?("some+channel")
    refute valid?("some(channel")
    refute valid?("some)channel")
    refute valid?("some[channel")
    refute valid?("some]channel")
    refute valid?("some{channel")
    refute valid?("some}channel")
    refute valid?("some<channel")
    refute valid?("some>channel")
    refute valid?("some'channel")
    refute valid?("some\"channel")
    refute valid?("some?channel")
  end
end
