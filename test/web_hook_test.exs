defmodule Poxa.WebHookTest do
  use ExUnit.Case
  alias Poxa.Channel
  alias Poxa.WebHookEventTable
  import :meck
  import Poxa.WebHook

  @table_name :web_hook_events

  setup_all do
    :application.set_env(:poxa, :app_secret, "secret")
    :application.set_env(:poxa, :app_key, "app_key")
    :application.set_env(:poxa, :web_hook, "web_hook_url")

    new Channel

    on_exit fn -> unload end
    :ok
  end

  setup do
    case :ets.info(@table_name) do
      :undefined -> WebHookEventTable.init
      _ -> :ets.delete_all_objects(@table_name)
    end
    :ok
  end


  test "connected is not saved" do
    assert {:ok, []} == handle_event(%{event: :connected}, [])
    assert WebHookEventTable.all == []
  end

  test "disconnected is not saved" do
    expect Channel, :occupied?, fn
      "channel_1" -> false
      "channel_2" -> true
    end
    assert {:ok, []} == handle_event(%{event: :disconnected, channels: ~w(channel_1 channel_2)}, [])
    assert WebHookEventTable.all == []
  end

  test "subscribed is not saved" do
    expect Channel, :subscription_count, fn _ -> 1 end
    assert {:ok, []} == handle_event(%{event: :subscribed, channel: "my_channel"}, [])
    assert WebHookEventTable.all == []
  end

  test "unsubscribed is not saved" do
    expect Channel, :occupied?, fn _ -> false end
    assert {:ok, []} == handle_event(%{event: :unsubscribed, channel: "my_channel"}, [])
    assert WebHookEventTable.all == []
  end

  test "channel_vacated is saved and delayed" do
    assert {:ok, []} == handle_event(%{event: :channel_vacated, channel: "my_channel"}, [])
    assert WebHookEventTable.all == [
      %{channel: "my_channel", name: "channel_vacated"}
    ]
    assert {_, []} = WebHookEventTable.ready
  end

  test "channel_occupied is saved" do
    assert {:ok, []} == handle_event(%{event: :channel_occupied, channel: "my_channel"}, [])
    assert WebHookEventTable.all == [
      %{channel: "my_channel", name: "channel_occupied"}
    ]
    assert {_, [_]} = WebHookEventTable.ready
  end

  test "client_event_message is saved" do
    assert {:ok, []} == handle_event(%{event: :client_event_message, socket_id: "socket_id", channels: ~w(channel_1 channel_2), name: "my_event", data: "data"}, [])
    assert WebHookEventTable.all == [
      %{channel: "channel_1", name: "client_event", event: "my_event", data: "data", socket_id: "socket_id"},
      %{channel: "channel_2", name: "client_event", event: "my_event", data: "data", socket_id: "socket_id"},
    ]
    assert {_, [_, _]} = WebHookEventTable.ready
  end

  test "member_added is saved" do
    assert {:ok, []} == handle_event(%{event: :member_added, channel: "channel", user_id: "user_id"}, [])
    assert WebHookEventTable.all == [
      %{channel: "channel", name: "member_added", user_id: "user_id"},
    ]
    assert {_, [_]} = WebHookEventTable.ready
  end

  test "member_removed is saved and delayed" do
    assert {:ok, []} == handle_event(%{event: :member_removed, channel: "channel", user_id: "user_id"}, [])
    assert WebHookEventTable.all == [
      %{channel: "channel", name: "member_removed", user_id: "user_id"},
    ]
    assert {_, []} = WebHookEventTable.ready
  end
end
