defmodule Poxa.WebHookTest do
  use ExUnit.Case
  alias Poxa.Channel
  import :meck
  import Poxa.WebHook

  setup_all do
    :application.set_env(:poxa, :app_secret, "secret")
    :application.set_env(:poxa, :app_key, "app_key")
    :application.set_env(:poxa, :web_hook, "web_hook_url")

    new HTTPoison
    expect HTTPoison, :post, fn url, body, headers ->
      args_map = %{url: url, body: JSX.decode!(body), headers: headers}
      send(self, args_map)
      {:ok, args_map}
    end

    new Channel

    on_exit fn -> unload end
    :ok
  end

  test "connected" do
    assert {:ok, []} == handle_event(%{event: :connected}, [])
  end

  test "disconnected" do
    expect Channel, :occupied?, fn
      "channel_1" -> false
      "channel_2" -> true
    end
    assert {:ok, []} == handle_event(%{event: :disconnected, channels: ~w(channel_1 channel_2)}, [])
    assert_received %{
      url: "web_hook_url",
      body: %{"events" => [%{"channel" => "channel_1", "name" => "channel_vacated"}]},
      headers: _headers
    }
  end

  test "subscribed sends channel_occupied event" do
    expect Channel, :subscription_count, fn _ -> 1 end
    assert {:ok, []} == handle_event(%{event: :subscribed, channel: "my_channel"}, [])
    assert_received %{
      url: "web_hook_url",
      body: %{"events" => [%{"channel" => "my_channel", "name" => "channel_occupied"}]},
      headers: _headers
    }
  end

  test "subscribed does not send channel_occupied event" do
    expect Channel, :subscription_count, fn _ -> 2 end
    assert {:ok, []} == handle_event(%{event: :subscribed, channel: "my_channel"}, [])
    refute_received %{url: _url, body: _body, headers: _headers}
  end

  test "unsubscribed sends channel_vacated event" do
    expect Channel, :occupied?, fn _ -> false end
    assert {:ok, []} == handle_event(%{event: :unsubscribed, channel: "my_channel"}, [])
    assert_received %{
      url: "web_hook_url",
      body: %{"events" => [%{"channel" => "my_channel", "name" => "channel_vacated"}]},
      headers: _headers
    }
  end

  test "unsubscribed does not send channel_vacated event" do
    expect Channel, :occupied?, fn _ -> true end
    assert {:ok, []} == handle_event(%{event: :unsubscribed, channel: "my_channel"}, [])
    refute_received %{url: _url, body: _body, headers: _headers}
  end

  test "client_event_message" do
    assert {:ok, []} == handle_event(%{event: :client_event_message, socket_id: "socket_id", channels: ~w(channel_1 channel_2), name: "my_event", data: "data"}, [])
    assert_received %{
      url: "web_hook_url",
      body: %{"events" =>
        [
          %{"channel" => "channel_1", "name" => "client_event", "data" => "data", "socket_id" => "socket_id"},
          %{"channel" => "channel_2", "name" => "client_event", "data" => "data", "socket_id" => "socket_id"}
        ]
      },
      headers: _headers
    }
  end
end
