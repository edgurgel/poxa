defmodule Poxa.Integration.TriggerEvent do
  use ExUnit.Case

  @moduletag :integration

  setup_all do
    Application.ensure_all_started(:pusher)
    :ok
  end

  setup do
    client = %Pusher.Client{
      endpoint: "localhost:8080",
      app_id: "app_id",
      app_key: "app_key",
      secret: "secret"
    }

    {:ok, client: client}
  end

  test "trigger event returns 200", %{client: client} do
    [channel, socket_id] = ["channel", "123.456"]

    assert Pusher.trigger(client, "test_event", %{}, channel, socket_id) == :ok
  end

  test "trigger event returns 400 on invalid channel", %{client: client} do
    [channel, socket_id] = ["channel:invalid", "123.456"]

    assert {:error, _} = Pusher.trigger(client, "test_event", %{}, channel, socket_id)
  end

  test "trigger event returns 400 on invalid socket_id", %{client: client} do
    [channel, socket_id] = ["channel", "123456"]

    assert {:error, _} = Pusher.trigger(client, "test_event", %{}, channel, socket_id)
  end

  test "trigger event returns 401 on invalid authentication" do
    [channel, socket_id] = ["channel", "123.456"]

    client = %Pusher.Client{
      endpoint: "localhost:8080",
      app_id: "app_id",
      app_key: "app_key",
      secret: "wrong_secret"
    }

    assert {:error, _} = Pusher.trigger(client, "test_event", %{}, channel, socket_id)
  end
end
