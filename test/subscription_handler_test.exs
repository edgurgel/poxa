defmodule Poxa.SubscriptionHandlerTest do
  use ExUnit.Case, async: true
  alias Poxa.Event
  alias Poxa.Channel
  use Mimic
  import Poxa.SubscriptionHandler

  setup do
    stub(Event)
    :ok
  end

  describe "init/1" do
    test "subscribe to internal events" do
      expect(Event, :subscribe, fn -> :ok end)
      assert init([]) == {:ok, []}
    end
  end

  describe "handle_info/2" do
    test "disconnected" do
      expect(Channel, :occupied?, fn "channel_1" -> false end)
      expect(Channel, :occupied?, fn "channel_2" -> true end)
      expect(Event, :notify, fn :channel_vacated, %{channel: "channel_1"} -> :ok end)

      assert {:noreply, []} ==
               handle_info(
                 {:internal_event,
                  %{
                    event: :disconnected,
                    channels: ~w(channel_1 channel_2),
                    socket_id: "socket_id"
                  }},
                 []
               )
    end

    test "subscribed sends channel_occupied event on first subscription" do
      expect(Channel, :subscription_count, fn "my_channel" -> 1 end)
      expect(Event, :notify, fn :channel_occupied, %{channel: "my_channel"} -> :ok end)

      assert {:noreply, []} ==
               handle_info(
                 {:internal_event,
                  %{event: :subscribed, channel: "my_channel", socket_id: "socket_id"}},
                 []
               )
    end

    test "subscribed does not send channel_occupied event other than first subscription" do
      expect(Channel, :subscription_count, fn "my_channel" -> 2 end)
      reject(&Event.notify/2)

      assert {:noreply, []} ==
               handle_info(
                 {:internal_event,
                  %{event: :subscribed, channel: "my_channel", socket_id: "socket_id"}},
                 []
               )
    end

    test "unsubscribed sends channel_vacated event" do
      expect(Channel, :occupied?, fn "my_channel" -> false end)
      expect(Event, :notify, fn :channel_vacated, %{channel: "my_channel"} -> :ok end)

      assert {:noreply, []} ==
               handle_info(
                 {:internal_event,
                  %{event: :unsubscribed, channel: "my_channel", socket_id: "socket_id"}},
                 []
               )
    end

    test "unsubscribed does not send channel_vacated event" do
      expect(Channel, :occupied?, fn "my_channel" -> true end)
      reject(&Event.notify/2)

      assert {:noreply, []} ==
               handle_info(
                 {:internal_event,
                  %{event: :unsubscribed, channel: "my_channel", socket_id: "socket_id"}},
                 []
               )
    end
  end
end
