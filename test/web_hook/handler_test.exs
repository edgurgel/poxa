defmodule Poxa.WebHook.HandlerTest do
  use ExUnit.Case, async: true
  alias Poxa.Event
  alias Poxa.WebHook.EventTable
  use Mimic
  import Poxa.WebHook.Handler

  @table_name :web_hook_events

  setup_all do
    :application.set_env(:poxa, :app_secret, "secret")
    :application.set_env(:poxa, :app_key, "app_key")
    :application.set_env(:poxa, :web_hook, "web_hook_url")

    :ok
  end

  setup do
    case :ets.info(@table_name) do
      :undefined -> EventTable.init()
      _ -> :ets.delete_all_objects(@table_name)
    end

    :ok
  end

  describe "init/1" do
    test "subscribe to internal events" do
      expect(Event, :subscribe, fn -> :ok end)
      assert init([]) == {:ok, nil}
    end
  end

  describe "handle_info/2" do
    test "connected is not saved" do
      assert {:noreply, []} == handle_info({:internal_event, %{event: :connected}}, [])
      assert EventTable.all() == []
    end

    test "disconnected is not saved" do
      assert {:noreply, []} ==
               handle_info(
                 {:internal_event, %{event: :disconnected, channels: ~w(channel_1 channel_2)}},
                 []
               )

      assert EventTable.all() == []
    end

    test "subscribed is not saved" do
      assert {:noreply, []} ==
               handle_info({:internal_event, %{event: :subscribed, channel: "my_channel"}}, [])

      assert EventTable.all() == []
    end

    test "unsubscribed is not saved" do
      assert {:noreply, []} ==
               handle_info({:internal_event, %{event: :unsubscribed, channel: "my_channel"}}, [])

      assert EventTable.all() == []
    end

    test "channel_vacated is saved and delayed" do
      assert {:noreply, []} ==
               handle_info(
                 {:internal_event, %{event: :channel_vacated, channel: "my_channel"}},
                 []
               )

      assert EventTable.all() == [
               %{channel: "my_channel", name: "channel_vacated"}
             ]

      assert {_, []} = EventTable.ready()
    end

    test "channel_occupied is saved" do
      assert {:noreply, []} ==
               handle_info(
                 {:internal_event, %{event: :channel_occupied, channel: "my_channel"}},
                 []
               )

      assert EventTable.all() == [
               %{channel: "my_channel", name: "channel_occupied"}
             ]

      assert {_, [_]} = EventTable.ready()
    end

    test "client_event_message is saved" do
      assert {:noreply, []} ==
               handle_info(
                 {:internal_event,
                  %{
                    event: :client_event_message,
                    socket_id: "socket_id",
                    channels: ~w(channel_1 channel_2),
                    name: "my_event",
                    data: "data"
                  }},
                 []
               )

      expected =
        [
          %{
            channel: "channel_1",
            name: "client_event",
            event: "my_event",
            data: "data",
            socket_id: "socket_id"
          },
          %{
            channel: "channel_2",
            name: "client_event",
            event: "my_event",
            data: "data",
            socket_id: "socket_id"
          }
        ]
        |> Enum.into(MapSet.new())

      assert MapSet.equal?(expected, Enum.into(EventTable.all(), MapSet.new()))
      assert {_, [_, _]} = EventTable.ready()
    end

    test "client_event_message with user_id is saved" do
      assert {:noreply, []} ==
               handle_info(
                 {:internal_event,
                  %{
                    event: :client_event_message,
                    socket_id: "socket_id",
                    channels: ~w(channel_1 channel_2),
                    name: "my_event",
                    data: "data",
                    user_id: "123"
                  }},
                 []
               )

      expected =
        [
          %{
            channel: "channel_1",
            name: "client_event",
            event: "my_event",
            data: "data",
            socket_id: "socket_id",
            user_id: "123"
          },
          %{
            channel: "channel_2",
            name: "client_event",
            event: "my_event",
            data: "data",
            socket_id: "socket_id",
            user_id: "123"
          }
        ]
        |> Enum.into(MapSet.new())

      assert MapSet.equal?(expected, Enum.into(EventTable.all(), MapSet.new()))
      assert {_, [_, _]} = EventTable.ready()
    end

    test "member_added is saved" do
      assert {:noreply, []} ==
               handle_info(
                 {:internal_event,
                  %{event: :member_added, channel: "channel", user_id: "user_id"}},
                 []
               )

      assert EventTable.all() == [
               %{channel: "channel", name: "member_added", user_id: "user_id"}
             ]

      assert {_, [_]} = EventTable.ready()
    end

    test "member_removed is saved and delayed" do
      assert {:noreply, []} ==
               handle_info(
                 {:internal_event,
                  %{event: :member_removed, channel: "channel", user_id: "user_id"}},
                 []
               )

      assert EventTable.all() == [
               %{channel: "channel", name: "member_removed", user_id: "user_id"}
             ]

      assert {_, []} = EventTable.ready()
    end
  end
end
