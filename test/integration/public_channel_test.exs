defmodule Poxa.Integration.PublicChannelTest do
  use ExUnit.Case

  @moduletag :integration

  setup_all do
    {:ok, pid} = PusherClient.connect!('ws://localhost:8080/app/app_key')
    info = PusherClient.client_info(pid)
    {:ok, [gen_event_pid: info.gen_event_pid, pid: pid]}
  end

  teardown_all context do
    PusherClient.disconnect!(context[:pid])
    :ok
  end

  defmodule EchoHandler do
    use GenEvent.Behaviour
    def init(pid), do: { :ok, pid }
    def handle_event(event, pid) do
      send pid, event
      { :ok, pid }
    end
  end

  test "subscribe on a public channel", context do
    gen_event_pid = context[:gen_event_pid]
    pid = context[:pid]

    :gen_event.add_handler(gen_event_pid, EchoHandler, self)
    PusherClient.subscribe!(pid, "channel")

    assert_receive {"channel", "pusher:subscription_succeeded", []}, 1_000
  end
end
