defmodule Poxa.Console do
  import JSX, only: [encode!: 1]
  use GenEvent

  @doc false
  def init(pid), do: {:ok, pid}

  @doc false
  def handle_event(%{event: :connected, socket_id: socket_id, origin: origin}, pid) do
    send_message("Connection", socket_id, "Origin: #{origin}", pid)
    {:ok, pid}
  end

  def handle_event(%{event: :disconnected, socket_id: socket_id, channels: channels, duration: duration}, pid) do
    send_message("Disconnection", socket_id, "Channels: #{inspect channels}, Lifetime: #{duration}s", pid)
    {:ok, pid}
  end

  def handle_event(%{event: :subscribed, socket_id: socket_id, channel: channel}, pid) do
    send_message("Subscribed", socket_id, "Channel: #{channel}", pid)
    {:ok, pid}
  end

  def handle_event(%{event: :unsubscribed, socket_id: socket_id, channel: channel}, pid) do
    send_message("Unsubscribed", socket_id, "Channel: #{channel}", pid)
    {:ok, pid}
  end

  def handle_event(%{event: :api_message, channels: channels, name: name}, pid) do
    send_message("API Message", "", "Channels: #{inspect channels}, Event: #{name}", pid)
    {:ok, pid}
  end

  def handle_event(%{event: :client_event_message, socket_id: socket_id, channels: channels, name: name}, pid) do
    send_message("Client Event Message", socket_id, "Channels: #{inspect channels}, Event: #{name}", pid)
    {:ok, pid}
  end

  def handle_event(%{event: :member_added, channel: channel, socket_id: socket_id, user_id: user_id}, pid) do
    send_message("Member added", socket_id, "Channel: #{inspect channel}, UserId: #{inspect user_id}", pid)
    {:ok, pid}
  end

  def handle_event(%{event: :member_removed, channel: channel, socket_id: socket_id, user_id: user_id}, pid) do
    send_message("Member removed", socket_id, "Channel: #{inspect channel}, UserId: #{inspect user_id}", pid)
    {:ok, pid}
  end

  def handle_event(%{event: :channel_vacated, channel: channel, socket_id: socket_id}, pid) do
    send_message("Channel vacated", socket_id, "Channel: #{inspect channel}", pid)
    {:ok, pid}
  end

  def handle_event(%{event: :channel_occupied, channel: channel, socket_id: socket_id}, pid) do
    send_message("Channel occupied", socket_id, "Channel: #{inspect channel}", pid)
    {:ok, pid}
  end

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
