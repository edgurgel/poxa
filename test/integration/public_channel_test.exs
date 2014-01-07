defmodule Poxa.Integration.PublicChannelTest do
  use ExUnit.Case

  setup_all do
    :ok = Pusher.start
    :application.set_env(:pusher, :host, "http://localhost")
    :application.set_env(:pusher, :port, "8080")
    :application.set_env(:pusher, :app_id, "app_id")
    :application.set_env(:pusher, :app_key, "app_key")
    :application.set_env(:pusher, :app_secret, "secret")
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
      pid <- event
      { :ok, pid }
    end
  end

  test "subscribe and receive events on a public channel", context do
    gen_event_pid = context[:gen_event_pid]
    pid = context[:pid]

    :gen_event.add_handler(gen_event_pid, EchoHandler, self)
    PusherClient.subscribe!(pid, "channel")

    assert Pusher.trigger("message1", [text: "Hello World!"], "channel") == 200
    assert Pusher.trigger("message2", [text: "Hi There!"], "channel") == 200

    assert_receive {"channel", "pusher:subscription_succeeded", []}, 1_000
    assert_receive {"channel", "message1", [{"text", "Hello World!"}]}, 1_000
    assert_receive {"channel", "message2", [{"text", "Hi There!"}]}, 1_000
  end
end
