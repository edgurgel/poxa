defmodule Poxa.WebHook.EventTableTest do
  use ExUnit.Case, async: true
  import Poxa.WebHook.EventTable

  @table_name :web_hook_events

  setup do
    case :ets.info(@table_name) do
      :undefined -> init()
      _ -> :ets.delete_all_objects(@table_name)
    end

    :ok
  end

  test "insert includes single event to the table" do
    result = insert("event")
    assert result == all()
  end

  test "insert includes event list to the table" do
    result = insert(~w(event1 event2))
    assert result == all()
  end

  test "insert does not add channel_occupied event, it removes the corresponding channel_vacated event when it is in the table" do
    vacated_event = %{name: "channel_vacated", channel: "channel"}
    result = insert(vacated_event)
    assert all() == result
    assert [] == insert(%{name: "channel_occupied", channel: "channel"})
    assert all() == []
  end

  test "insert does not add member_added event, it removes the corresponding member_removed event when it is in the table" do
    removed_event = %{name: "member_removed", user_id: "123", channel: "channel"}
    result = insert(removed_event)
    assert all() == result
    assert [] == insert(%{name: "member_added", user_id: "123", channel: "channel"})
    assert all() == []
  end

  test "ready returns events ready to be sent" do
    result = insert(~w(ready_event), 0)
    assert result == all()
    assert {_, ~w(ready_event)} = ready()
  end

  test "ready does not return events to be delivered in the future" do
    result = insert(~w(ready_event), 0)
    insert(~w(delayed_event), 10000)
    assert ~w(delayed_event ready_event) == Enum.sort(all())
    assert {_, ^result} = ready()
  end
end
