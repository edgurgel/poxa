Application.ensure_all_started(:mimic)
Mimic.copy(Poxa.Authentication)
Mimic.copy(Poxa.AuthSignature)
Mimic.copy(Signaturex)
Mimic.copy(:cowboy_req)
Mimic.copy(Poison)
Mimic.copy(Poxa.Channel)
Mimic.copy(Poxa.Event)
Mimic.copy(Poxa.PusherEvent)
Mimic.copy(Poxa.PresenceChannel)
Mimic.copy(Poxa.SocketId)
Mimic.copy(Poxa.PresenceSubscription)
Mimic.copy(Poxa.Time)
Mimic.copy(Poxa.Subscription)
Mimic.copy(Poxa.registry)
Mimic.copy(HTTPoison)
ExUnit.start
ExUnit.configure(exclude: :pending)

defmodule Connection do
  def connect do
    {:ok, pid} = PusherClient.start_link("ws://localhost:8080", "app_key", "secret", stream_to: self())

    socket_id = receive do
      %{channel: nil, event: "pusher:connection_established", data: %{"socket_id" => socket_id}} -> socket_id
    end
    {:ok, pid, socket_id}
  end
end
