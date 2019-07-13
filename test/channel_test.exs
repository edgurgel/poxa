defmodule Poxa.ChannelTest do
  use ExUnit.Case, async: true
  import Poxa.Channel
  use Mimic
  doctest Poxa.Channel

  setup do
    stub(Poxa.registry())
    :ok
  end

  test "occupied? returns false for empty channel" do
    expect(Poxa.registry(), :subscription_count, fn "channel", :_ -> 0 end)

    refute occupied?("channel")
  end

  test "occupied? returns true for populated channel" do
    expect(Poxa.registry(), :subscription_count, fn "channel", :_ -> 42 end)

    assert occupied?("channel")
  end

  test "list all channels" do
    channels = ~w(channel1 channel2 channel3)
    expect(Poxa.registry(), :channels, fn _ -> ~w(channel1 channel2 channel3) end)

    assert all() == channels
  end

  test "list channels of a pid" do
    channels = ~w(channel1 channel2 channel3)
    pid = self()
    expect(Poxa.registry(), :channels, fn ^pid -> ~w(channel1 channel2 channel3) end)

    assert all(self()) == channels
  end

  test "channel is member? returning true" do
    pid = self()
    expect(Poxa.registry(), :subscription_count, fn "channel", ^pid -> 1 end)

    assert member?("channel", self())
  end

  test "channel is subscribed returning false" do
    pid = self()
    expect(Poxa.registry(), :subscription_count, fn "channel", ^pid -> 0 end)

    refute member?("channel", self())
  end

  test "subscription_count on channel" do
    expect(Poxa.registry(), :subscription_count, fn "channel", :_ -> 2 end)

    assert subscription_count("channel") == 2
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
