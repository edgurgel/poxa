defmodule Poxa.Integration.TriggerEvent do
  use ExUnit.Case, async: true

  @moduletag :integration

  setup_all do
    Application.ensure_all_started(:pusher)
    Pusher.configure!("localhost", 8080, "app_id", "app_key", "secret")
    :ok
  end

  test "trigger event returns 200" do
    [channel, socket_id] = ["channel", "123.456"]

    assert Pusher.trigger("test_event", %{}, channel, socket_id) == 200
  end

  test "trigger event returns 400 on invalid channel" do
    [channel, socket_id] = ["channel:invalid", "123.456"]

    assert Pusher.trigger("test_event", %{}, channel, socket_id) == 400
  end

  test "trigger event returns 400 on invalid socket_id" do
    [channel, socket_id] = ["channel", "123456"]

    assert Pusher.trigger("test_event", %{}, channel, socket_id) == 400
  end
end
