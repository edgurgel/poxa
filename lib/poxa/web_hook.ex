defmodule Poxa.WebHook do
  use GenEvent
  alias Poxa.WebHookEvent
  alias Poxa.CryptoHelper

  @doc false
  def handle_event(%{event: :channel_vacated, channel: channel}, []) do
    WebHookEvent.channel_vacated(channel) |> send_web_hook
  end

  def handle_event(%{event: :channel_occupied, channel: channel}, []) do
    WebHookEvent.channel_occupied(channel) |> send_web_hook
  end

  def handle_event(%{event: :member_added, channel: channel, user_id: user_id}, []) do
    WebHookEvent.member_added(channel, user_id) |> send_web_hook
  end

  def handle_event(%{event: :member_removed, channel: channel, user_id: user_id}, []) do
    WebHookEvent.member_removed(channel, user_id) |> send_web_hook
  end

  def handle_event(%{event: :client_event_message, socket_id: socket_id, channels: channels, name: name, data: data}, []) do
    for c <- channels do
      WebHookEvent.client_event(c, name, data, socket_id, nil)
    end |> send_web_hook
  end

  # Events that cannot trigger any webhook event
  def handle_event(_, []), do: {:ok, []}

  defp send_web_hook(event) when not is_list(event), do: send_web_hook([event])
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
      "Content-Type"       => "application/json",
      "X-Pusher-Key"       => app_key,
      "X-Pusher-Signature" => CryptoHelper.hmac256_to_string(app_secret, body)
    }
  end

  defp time_ms, do: :erlang.system_time(1000)
end
