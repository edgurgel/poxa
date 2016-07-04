defmodule Poxa.Integration.ConnectionTest do
  use ExUnit.Case

  @moduletag :integration

  setup_all do
    Application.ensure_all_started(:pusher)
    Pusher.configure!("localhost", 8080, "app_id", "app_key", "secret")
    :ok
  end

  test "connects and receive socket_id" do
    {:ok, _pid} = PusherClient.start_link("ws://localhost:8080", "app_key", "secret", stream_to: self)
    assert_receive %{channel: nil,
                     event: "pusher:connection_established",
                     data: %{"socket_id" => socket_id,
                             "activity_timeout" => 120}}, 1_000
    assert is_binary(socket_id)
  end
end
