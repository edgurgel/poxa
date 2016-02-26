defmodule Poxa.EventTest do
  use ExUnit.Case
  alias Poxa.Event

  defmodule TestHandler do
    use GenEvent

    def handle_event(%{event: :failed_handling}, _pid) do
      :error
    end

    def handle_event(event_data, pid) do
      send pid, event_data
      {:ok, pid}
    end
  end

  test "notifies handler" do
    :ok = Event.add_handler({TestHandler, self}, self)
    :ok = Event.notify(:successful_handling, %{data: :map})
    assert_receive %{event: :successful_handling, data: :map}
  end

  test "handler failures are notified" do
    :ok = Event.add_handler({TestHandler, self}, self)
    :ok = Event.notify(:failed_handling, %{})
    assert_receive {:gen_event_EXIT, _, _}
  end
end
