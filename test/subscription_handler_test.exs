defmodule Poxa.SubscriptionHandlerTest do
  use ExUnit.Case, async: true
  alias Poxa.Event
  alias Poxa.Channel
  import Mimic
  import Poxa.SubscriptionHandler

  setup :verify_on_exit!

  setup do
    stub(Event)
    :ok
  end

  test "disconnected" do
    expect(Channel, :occupied?, fn "channel_1" -> false end)
    expect(Channel, :occupied?, fn "channel_2" -> true end)
    expect(Event, :notify, fn :channel_vacated, %{channel: "channel_1"} -> :ok end)

    assert {:ok, []} == handle_event(%{event: :disconnected, channels: ~w(channel_1 channel_2), socket_id: "socket_id"}, [])
  end

  test "subscribed sends channel_occupied event on first subscription" do
    expect(Channel, :subscription_count, fn "my_channel" -> 1 end)
    expect(Event, :notify, fn :channel_occupied, %{channel: "my_channel"} -> :ok end)

    assert {:ok, []} == handle_event(%{event: :subscribed, channel: "my_channel", socket_id: "socket_id"}, [])
  end

  test "subscribed does not send channel_occupied event other than first subscription" do
    expect(Channel, :subscription_count, fn "my_channel" -> 2 end)
    reject(&Event.notify/2)
    assert {:ok, []} == handle_event(%{event: :subscribed, channel: "my_channel", socket_id: "socket_id"}, [])
  end

  test "unsubscribed sends channel_vacated event" do
    expect(Channel, :occupied?, fn "my_channel" -> false end)
    expect(Event, :notify, fn :channel_vacated, %{channel: "my_channel"} -> :ok end)

    assert {:ok, []} == handle_event(%{event: :unsubscribed, channel: "my_channel", socket_id: "socket_id"}, [])
  end

  test "unsubscribed does not send channel_vacated event" do
    expect(Channel, :occupied?, fn "my_channel" -> true end)
    reject(&Event.notify/2)
    assert {:ok, []} == handle_event(%{event: :unsubscribed, channel: "my_channel", socket_id: "socket_id"}, [])
  end
end
