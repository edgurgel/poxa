defmodule Poxa.Integration.PublicChannelTest do
  use ExUnit.Case

  @moduletag :integration

  setup_all do
    {:ok, pid} = PusherClient.start_link('ws://localhost:8080/app/app_key')
    {:ok, [pid: pid]}
  end

  teardown_all context do
    PusherClient.disconnect!(context[:pid])
    :ok
  end

  defmodule EchoHandler do
    use GenEvent

    def init(pid), do: { :ok, pid }
    def handle_event(event, pid) do
      send pid, event
      { :ok, pid }
    end
  end

  test "subscribe on a public channel", context do
    pid = context[:pid]

    PusherClient.add_handler(pid, EchoHandler)
    PusherClient.subscribe!(pid, "channel")

    assert_receive {"channel", "pusher:subscription_succeeded", %{}}, 5_000
  end
end
