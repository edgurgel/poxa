defmodule Poxa.ChannelTest do
  use ExUnit.Case
  import SpawnHelper
  import Poxa.Channel
  doctest Poxa.Channel

  test "occupied? returns false for empty channel" do
    register_to_channel("other_app_id", "a channel")

    refute occupied?("a channel", "app_id")
  end

  test "occupied? returns true for populated channel" do
    register_to_channel("app_id", "a channel")

    assert occupied?("a channel", "app_id")
  end

  test "list all channels" do
    register_to_channel("other_app_id", "other_channel")
    register_to_channel("app_id", "channel1")
    register_to_channel("app_id", "channel2")
    spawn_registered_process("app_id", "channel3")

    assert "channel1" in all("app_id")
    assert "channel2" in all("app_id")
    assert "channel3" in all("app_id")
    refute "other_channel" in all("app_id")
  end

  test "list channels of a pid" do
    register_to_channel("app_id", "channel1")
    register_to_channel("app_id", "channel2")
    register_to_channel("app_id", "channel3")

    assert all("app_id", self) == ["channel1", "channel2", "channel3"]
  end

  test "channel is subscribed? returning true" do
    register_to_channel("app_id", "channel")

    assert subscribed?("channel", "app_id", self)
  end

  test "channel is subscribed returning false" do
    register_to_channel("other_app_id", "channel")
    register_to_channel("app_id", "other_channel")

    refute subscribed?("channel", "app_id", self)
  end

  test "subscription_count on channel" do
    register_to_channel("app_id", "channel")
    spawn_registered_process("app_id", "channel")

    assert subscription_count("channel", "app_id") == 2
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
