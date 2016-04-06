defmodule Poxa.WebHook.Dispatcher do
  @moduledoc """
  This module models the behaviour of a process used to send the web hook requests.
  It retrieves events from the ETS table and removes them on success.
  """

  use GenServer

  alias Poxa.WebHook.EventTable
  alias Poxa.CryptoHelper
  require Logger

  @timeout 1500

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  @doc false
  def handle_info(:timeout, state) do
    case EventTable.ready do
      {_, [] } -> {:noreply, state, @timeout}
      {timestamp, events} ->
        :ok = send_web_hook!(events)
        EventTable.clear_older(timestamp)
        {:noreply, state, @timeout}
    end
  end

  @doc """
  Starts the GenServer with timeout of 1.5 seconds. After this time, the events will be sent.
  """
  def init(state) do
    EventTable.init
    {:ok, state, @timeout}
  end

  defp send_web_hook!(events) do
    Logger.debug "Sending webhook request."
    body = JSX.encode! %{time_ms: time_ms, events: events}
    {:ok, url} = Application.fetch_env(:poxa, :web_hook)
    case HTTPoison.post(url, body, pusher_headers(body)) do
      {:ok, _} -> :ok
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

  defp time_ms, do: :erlang.system_time(:milli_seconds)
end
