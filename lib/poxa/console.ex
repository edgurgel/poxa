defmodule Poxa.Console do
  import JSEX, only: [encode!: 1]

  def connected(socket_id, origin) do
    send_message("Connection", socket_id, "Origin: #{origin}")
  end

  def disconnected(socket_id, channels) when is_list(channels) do
    send_message("Disconnection", socket_id, "Channels: #{inspect channels}")
  end

  def subscribed(socket_id, channel) do
    send_message("Subscribed", socket_id, "Channel: #{channel}")
  end

  def unsubscribed(socket_id, channel) do
    send_message("Unsubscribed", socket_id, "Channel: #{channel}")
  end

  def api_message(channels, message) do
    send_message("API Message", "", "Channels: #{inspect channels}, Event: #{message["event"]}")
  end

  def client_event_message(socket_id, channels, message) do
    send_message("Client Event Message", socket_id, "Channels: #{inspect channels}, Event: #{message["event"]}")
  end

  defp send_message(type, socket_id, details) do
    message(type, socket_id, details) |> send
  end

  defp send(message) do
    :gproc.send({:p, :l, :console}, {self, message |> encode!})
  end

  defp message(type, socket_id, details) do
    [
      type: type,
      socket: socket_id,
      details: details,
      time: time
    ]
  end

  defp time do
    {_, {hour, min, sec}} = :erlang.localtime
    :io_lib.format("~2w:~2..0w:~2..0w", [hour, min, sec]) |> to_string
  end
end
