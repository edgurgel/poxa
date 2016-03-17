defmodule Poxa.ChannelTest do
  use ExUnit.Case
  import SpawnHelper
  import Poxa.Channel
  doctest Poxa.Channel

  test "occupied? returns false for empty channel" do
    refute occupied?("unoccupied channel")
  end

  test "occupied? returns true for populated channel" do
    register_to_channel("a populated channel")

    assert occupied?("a populated channel")
  end

  test "list all channels" do
    register_to_channel("channel1")
    register_to_channel("channel2")
    spawn_registered_process("channel3")

    expected = Enum.into(~w(channel1 channel2 channel3), MapSet.new)
    assert MapSet.equal?(Enum.into(all, MapSet.new), expected)
  end

  test "list channels of a pid" do
    register_to_channel("channel_1")
    register_to_channel("channel_2")
    register_to_channel("channel_3")
    spawn_registered_process("channel4")

    assert all(self) == ["channel_1", "channel_2", "channel_3"]
  end

  test "channel is member? returning true" do
    register_to_channel("subscribed channel")

    assert member?("subscribed channel", self)
  end

  test "channel is subscribed returning false" do
    refute member?("an unoccupied channel", self)
  end

  test "subscription_count on channel" do
    register_to_channel("the channel")
    spawn_registered_process("the channel")

    assert subscription_count("the channel") == 2
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
