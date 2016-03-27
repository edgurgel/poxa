defmodule Poxa.EventTest do
  use ExUnit.Case
  import :meck
  alias Poxa.Event
  alias Poxa.SocketId

  setup do
    new SocketId
    { :ok, _ } = GenEvent.start_link(name: Poxa.Event)
    on_exit fn -> unload end
    :ok
  end

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

  test "notifies handler with a socket_id" do
    :ok = Event.add_handler({TestHandler, self}, self)
    :ok = Event.notify(:successful_handling, %{socket_id: :socket_id, data: :map})
    assert_receive %{event: :successful_handling,
                     data: :map,
                     socket_id: :socket_id}
  end

  test "notifies handler without a socket_id" do
    :ok = Event.add_handler({TestHandler, self}, self)

    expect(SocketId, :mine, 0, :socket_id)

    :ok = Event.notify(:successful_handling, %{data: :map})
    assert_receive %{event: :successful_handling, data: :map, socket_id: :socket_id}
    assert validate(SocketId)
  end

  test "handler failures are notified" do
    :ok = Event.add_handler({TestHandler, self}, self)
    :ok = Event.notify(:failed_handling, %{socket_id: :socket_id})
    assert_receive {:gen_event_EXIT, _, _}
  end
end
