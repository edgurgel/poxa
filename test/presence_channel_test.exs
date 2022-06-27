defmodule Poxa.PresenceChannelTest do
  use ExUnit.Case, async: true
  use Mimic
  import Poxa.PresenceChannel

  setup do
    stub(Poxa.registry())
    :ok
  end

  test "return unique user ids currently subscribed" do
    expect(Poxa.registry(), :unique_subscriptions, fn "presence-channel" ->
      %{"user_id1" => %{key: "value"}, "user_id2" => %{a: "b"}}
    end)

    assert users("presence-channel") == ["user_id1", "user_id2"]
  end

  test "return number of unique subscribed users" do
    expect(Poxa.registry(), :unique_subscriptions, fn "presence-channel" ->
      %{"user_id1" => %{key: "value"}, "user_id2" => %{a: "b"}}
    end)

    assert user_count("presence-channel") == 2
  end

  test "return user_id if available" do
    expect(Poxa.registry(), :fetch, fn "presence-channel" ->
      %{user_id: 123, user_info: %{key: "value"}}
    end)

    assert my_user_id("presence-channel") == 123
  end

  test "return nil if user_id is not available" do
    expect(Poxa.registry(), :fetch, fn "presence-channel" -> nil end)

    assert my_user_id("presence-channel") == nil
  end
end
