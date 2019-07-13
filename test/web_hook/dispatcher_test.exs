defmodule Poxa.WebHook.DispatcherTest do
  use ExUnit.Case, async: true
  alias Poxa.WebHook.EventTable
  use Mimic
  import Poxa.WebHook.Dispatcher

  @table_name :web_hook_events

  setup_all do
    :application.set_env(:poxa, :app_secret, "secret")
    :application.set_env(:poxa, :app_key, "app_key")
    :application.set_env(:poxa, :web_hook, "web_hook_url")

    :ok
  end

  setup do
    stub(HTTPoison, :post, fn url, body, headers ->
      args_map = %{url: url, body: Jason.decode!(body), headers: headers}
      send(self(), args_map)
      {:ok, args_map}
    end)

    :ok
  end

  setup do
    case :ets.info(@table_name) do
      :undefined -> EventTable.init()
      _ -> :ets.delete_all_objects(@table_name)
    end

    :ok
  end

  test "sends ready events on timeout" do
    EventTable.insert(~w(event_1 event_2))
    EventTable.insert("delayed_event", 10000)
    assert handle_info(:timeout, nil) == {:noreply, nil, 1500}
    assert ~w(delayed_event) == EventTable.all()

    assert_received %{
      url: "web_hook_url",
      body: %{
        "time_ms" => _,
        "events" => ~w(event_1 event_2)
      },
      headers: %{
        "Content-Type" => "application/json",
        "X-Pusher-Key" => "app_key",
        "X-Pusher-Signature" => _
      }
    }
  end
end
