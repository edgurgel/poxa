defmodule Poxa.WebHook do
  use GenEvent
  alias Poxa.Channel
  alias Poxa.WebHookEvent
  alias Poxa.CryptoHelper

  @doc false
  def handle_event(%{event: :connected}, []) do
    # It cannot trigger any webhook event
    {:ok, []}
  end

  def handle_event(%{event: :disconnected, channels: channels}, []) do
    for c <- channels, !Channel.occupied?(c) do
      WebHookEvent.channel_vacated(c)
    end |> send_web_hook
  end

  def handle_event(%{event: :subscribed, channel: channel}, []) do
    for c <- [channel], Channel.subscription_count(c) == 1 do
      WebHookEvent.channel_occupied(c)
    end |> send_web_hook
  end

  def handle_event(%{event: :unsubscribed, channel: channel}, []) do
    for c <- [channel], !Channel.occupied?(c) do
      WebHookEvent.channel_vacated(c)
    end |> send_web_hook
  end

  def handle_event(%{event: :api_message}, []) do
    # It cannot trigger any webhook event
    {:ok, []}
  end

  def handle_event(%{event: :client_event_message, socket_id: socket_id, channels: channels, name: name, data: data}, []) do
    for c <- channels do
      WebHookEvent.client_event(c, name, data, socket_id, nil)
    end |> send_web_hook
  end

  defp send_web_hook([]), do: {:ok, []}
  defp send_web_hook(events) do
    body = JSX.encode! %{time_ms: time_ms, events: events}
    {:ok, url} = Application.fetch_env(:poxa, :web_hook)
    case HTTPoison.post(url, body, pusher_headers(body)) do
      {:ok, _} -> {:ok, []}
      error -> error
    end
  end

  defp pusher_headers(body) do
    {:ok, app_key} = Application.fetch_env(:poxa, :app_key)
    {:ok, app_secret} = Application.fetch_env(:poxa, :app_secret)
    %{
      "X-Pusher-Key"       => app_key,
      "X-Pusher-Signature" => CryptoHelper.hmac256_to_string(app_secret, body)
    }
  end

  defp time_ms, do: :erlang.system_time(1000)
end
