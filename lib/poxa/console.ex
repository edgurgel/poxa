defmodule Poxa.Console do
  import JSEX, only: [encode!: 1]

  def connected(socket_id, origin) do
    message("Connection", socket_id, "Origin: #{origin}") |> send
  end

  def disconnected(socket_id, channels) when is_list(channels) do
    message("Disconnection", socket_id, "Channels: #{inspect channels}") |> send
  end

  def subscribed(socket_id, channel) do
    message("Subscribed", socket_id, "Channel: #{channel}") |> send
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
