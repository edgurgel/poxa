defmodule Poxa.EventTest do
  use ExUnit.Case, async: true
  use Mimic
  alias Poxa.Event
  alias Poxa.SocketId

  setup do
    stub(SocketId)
    stub(:gproc)
    :ok
  end

  describe "subscribe/0" do
    test "register for internal events" do
      expect(:gproc, :reg, fn {:p, :l, :internal_event} -> :ok end)
      Event.subscribe()
    end
  end

  describe "notify/2" do
    test "notifies handler with a socket_id" do
      event = %{event: :successful_handling, data: :map, socket_id: :socket_id}
      expect(:gproc, :send, fn {:p, :l, :internal_event}, {:internal_event, ^event} -> :ok end)

      :ok = Event.notify(:successful_handling, %{socket_id: :socket_id, data: :map})
    end

    test "notifies handler without a socket_id" do
      expect(SocketId, :mine, fn -> :socket_id end)

      event = %{event: :successful_handling, data: :map, socket_id: :socket_id}
      expect(:gproc, :send, fn {:p, :l, :internal_event}, {:internal_event, ^event} -> :ok end)

      :ok = Event.notify(:successful_handling, %{data: :map})
    end
  end
end
