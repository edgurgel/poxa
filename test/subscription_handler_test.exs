defmodule Poxa.SubscriptionHandlerTest do
  use ExUnit.Case
  alias Poxa.Event
  alias Poxa.Channel
  import :meck
  import Poxa.SubscriptionHandler

  setup_all do
    expect Event, :notify, fn event, event_data ->
      send(self, {event, event_data})
      :ok
    end

    on_exit fn -> unload end
    :ok
  end

  test "disconnected" do
    expect Channel, :occupied?, fn
      "channel_1" -> false
      "channel_2" -> true
    end
    assert {:ok, []} == handle_event(%{event: :disconnected, channels: ~w(channel_1 channel_2), socket_id: "socket_id"}, [])
    assert_received {:channel_vacated, %{channel: "channel_1"}}
  end

  test "subscribed sends channel_occupied event on first subscription" do
    expect Channel, :subscription_count, fn _ -> 1 end
    assert {:ok, []} == handle_event(%{event: :subscribed, channel: "my_channel", socket_id: "socket_id"}, [])
    assert_received {:channel_occupied, %{channel: "my_channel"}}
  end

  test "subscribed does not send channel_occupied event other than first subscription" do
    expect Channel, :subscription_count, fn _ -> 2 end
    assert {:ok, []} == handle_event(%{event: :subscribed, channel: "my_channel", socket_id: "socket_id"}, [])
    refute_received {:channel_occupied, %{channel: "my_channel"}}
  end

  test "unsubscribed sends channel_vacated event" do
    expect Channel, :occupied?, fn _ -> false end
    assert {:ok, []} == handle_event(%{event: :unsubscribed, channel: "my_channel", socket_id: "socket_id"}, [])
    assert_received {:channel_vacated, %{channel: "my_channel"}}
  end

  test "unsubscribed does not send channel_vacated event" do
    expect Channel, :occupied?, fn _ -> true end
    assert {:ok, []} == handle_event(%{event: :unsubscribed, channel: "my_channel", socket_id: "socket_id"}, [])
    refute_received {:channel_vacated, %{channel: "my_channel"}}
  end
end
