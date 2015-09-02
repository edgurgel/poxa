defmodule Poxa.ChannelTest do
  use ExUnit.Case
  import SpawnHelper
  import Poxa.Channel
  doctest Poxa.Channel

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

    assert "channel1" in all
    assert "channel2" in all
    assert "channel3" in all
  end

  test "list channels of a pid" do
    register_to_channel("channel1")
    register_to_channel("channel2")
    register_to_channel("channel3")

    assert all(self) == ["channel1", "channel2", "channel3"]
  end

  test "channel is subscribed? returning true" do
    register_to_channel("channel")

    assert subscribed?("channel", self)
  end

  test "channel is subscribed returning false" do
    refute subscribed?("channel", self)
  end

  test "subscription_count on channel" do
    register_to_channel("channel")
    spawn_registered_process("channel")

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
