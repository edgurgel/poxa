defmodule Poxa.Console do
  import JSX, only: [encode!: 1]
  use GenEvent

  @doc false
  def init([pid, app_id]), do: {:ok, {pid, app_id}}

  @doc false
  def handle_event(%{event: :connected, app_id: app_id, socket_id: socket_id, origin: origin}, {pid, app_id}) do
    send_message("Connection", socket_id, "Origin: #{origin}", pid)
    {:ok, {pid, app_id}}
  end

  def handle_event(%{event: :disconnected, app_id: app_id, socket_id: socket_id, channels: channels, duration: duration}, {pid, app_id}) do
    send_message("Disconnection", socket_id, "Channels: #{inspect channels}, Lifetime: #{duration}s", pid)
    {:ok, {pid, app_id}}
  end

  def handle_event(%{event: :subscribed, app_id: app_id, socket_id: socket_id, channel: channel}, {pid, app_id}) do
    send_message("Subscribed", socket_id, "Channel: #{channel}", pid)
    {:ok, {pid, app_id}}
  end

  def handle_event(%{event: :unsubscribed, app_id: app_id, socket_id: socket_id, channel: channel}, {pid, app_id}) do
    send_message("Unsubscribed", socket_id, "Channel: #{channel}", pid)
    {:ok, {pid, app_id}}
  end

  def handle_event(%{event: :api_message, app_id: app_id, channels: channels, name: name}, {pid, app_id}) do
    send_message("API Message", "", "Channels: #{inspect channels}, Event: #{name}", pid)
    {:ok, {pid, app_id}}
  end

  def handle_event(%{event: :client_event_message, app_id: app_id, socket_id: socket_id, channels: channels, name: name}, {pid, app_id}) do
    send_message("Client Event Message", socket_id, "Channels: #{inspect channels}, Event: #{name}", pid)
    {:ok, {pid, app_id}}
  end

  def handle_event(_data, state), do: {:ok, state}

  defp send_message(type, socket_id, details, pid) do
    msg = message(type, socket_id, details) |> encode!
    send(pid, msg)
  end

  defp message(type, socket_id, details) do
    %{ type: type, socket: socket_id, details: details, time: time }
  end

  defp time do
    {_, {hour, min, sec}} = :erlang.localtime
    :io_lib.format("~2w:~2..0w:~2..0w", [hour, min, sec]) |> to_string
  end
end
