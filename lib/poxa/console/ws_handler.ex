defmodule Poxa.Console.WSHandler do
  @behaviour :cowboy_websocket_handler
  require Logger
  alias Poxa.Authentication

  @doc false
  def init(_transport, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  @doc false
  def websocket_init(_transport_name, req, _opts) do
    {method, req} = :cowboy_req.method(req)
    {path, req} = :cowboy_req.path(req)
    {qs_vals, req} = :cowboy_req.qs_vals(req)

    if Authentication.check(method, path, "", qs_vals) do
      Poxa.Event.subscribe()
      {:ok, req, nil}
    else
      Logger.error "Failed to authenticate on Console Websocket"
      {:shutdown, req}
    end
  end

  @doc false
  def websocket_handle(_data, req, state), do: {:ok, req, state}

  def websocket_info({:internal_event, event}, req, state) do
    {:reply, {:text, do_websocket_info(event)}, req, state}
  end

  def websocket_terminate(_reason, _req, _state), do: :ok

  defp do_websocket_info(%{event: :connected, socket_id: socket_id, origin: origin}) do
    build_message("Connection", socket_id, "Origin: #{origin}")
  end

  defp do_websocket_info(%{event: :disconnected, socket_id: socket_id, channels: channels, duration: duration}) do
    build_message("Disconnection", socket_id, "Channels: #{inspect channels}, Lifetime: #{duration}s")
  end

  defp do_websocket_info(%{event: :subscribed, socket_id: socket_id, channel: channel}) do
    build_message("Subscribed", socket_id, "Channel: #{channel}")
  end

  defp do_websocket_info(%{event: :unsubscribed, socket_id: socket_id, channel: channel}) do
    build_message("Unsubscribed", socket_id, "Channel: #{channel}")
  end

  defp do_websocket_info(%{event: :api_message, channels: channels, name: name}) do
    build_message("API Message", "", "Channels: #{inspect channels}, Event: #{name}")
  end

  defp do_websocket_info(%{event: :client_event_message, socket_id: socket_id, channels: channels, name: name}) do
    build_message("Client Event Message", socket_id, "Channels: #{inspect channels}, Event: #{name}")
  end

  defp do_websocket_info(%{event: :member_added, channel: channel, socket_id: socket_id, user_id: user_id}) do
    build_message("Member added", socket_id, "Channel: #{inspect channel}, UserId: #{inspect user_id}")
  end

  defp do_websocket_info(%{event: :member_removed, channel: channel, socket_id: socket_id, user_id: user_id}) do
    build_message("Member removed", socket_id, "Channel: #{inspect channel}, UserId: #{inspect user_id}")
  end

  defp do_websocket_info(%{event: :channel_vacated, channel: channel, socket_id: socket_id}) do
    build_message("Channel vacated", socket_id, "Channel: #{inspect channel}")
  end

  defp do_websocket_info(%{event: :channel_occupied, channel: channel, socket_id: socket_id}) do
    build_message("Channel occupied", socket_id, "Channel: #{inspect channel}")
  end

  defp build_message(type, socket_id, details) do
    message(type, socket_id, details) |> Poison.encode!
  end

  defp message(type, socket_id, details) do
    %{ type: type, socket: socket_id, details: details, time: time() }
  end

  defp time do
    {_, {hour, min, sec}} = :erlang.localtime
    :io_lib.format("~2w:~2..0w:~2..0w", [hour, min, sec]) |> to_string
  end
end
