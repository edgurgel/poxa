defmodule Poxa.EventHandler do
  @moduledoc """
  This module contains Cowboy HTTP handler callbacks to request on /apps/:app_id/events

  More info on Cowboy HTTP handler at: http://ninenines.eu/docs/en/cowboy/HEAD/guide/http_handlers

  More info on Pusher events at: http://pusher.com/docs/rest_api
  """
  alias Poxa.Authentication
  alias Poxa.PusherEvent
  require Lager

  @error_json JSEX.encode!([error: "invalid json"])
  @doc """
  If the body is a valid JSON, the state of the handler will be the body
  Otherwise the response will be a 400 status code
  """
  def init(_transport, req, _opts) do
    {:ok, body, req} = :cowboy_req.body(req)
    if JSEX.is_json?(body) do
      {:ok, req, body}
    else
      Lager.info "Invalid JSON on Event Handler: #{body}"
      {:ok, req} = :cowboy_req.reply(400, [], @error_json, req)
      {:shutdown, req, nil}
    end
  end

  @authentication_error_json JSEX.encode!([error: "Authentication error"])
  @invalid_event_json JSEX.encode!([error: "Event must have channel(s), name, and data"])

  @doc """
  Decode the JSON and send events to channels if successful
  """
  def handle(req, body) do
    {qs_vals, req} = :cowboy_req.qs_vals(req)
    {method, req} = :cowboy_req.method(req)
    {path, req} = :cowboy_req.path(req)
    # http://pusher.com/docs/rest_api#authentication
    case Authentication.check(method, path, body, qs_vals) do
      :ok ->
        request_data = JSEX.decode!(body)
        {request_data, channels, exclude} = PusherEvent.parse_channels(request_data)
        if channels && PusherEvent.valid?(request_data) do
          message = prepare_message(request_data)
          PusherEvent.send_message_to_channels(channels, message, exclude)
          {:ok, req} = :cowboy_req.reply(200, [], "{}", req)
          {:ok, req, nil}
        else
          Lager.info "No channel defined"
          {:ok, req} = :cowboy_req.reply(400, [], @invalid_event_json, req)
          {:ok, req, nil}
        end
      _ ->
        Lager.info "Authentication failed"
        {:ok, req} = :cowboy_req.reply(401, [], @authentication_error_json, req)
        {:ok, req, nil}
    end
  end

  def terminate(_reason, _req, _state), do: :ok

  # Remove name and add event to the response
  defp prepare_message(message) do
    {event, message} = ListDict.pop(message, "name")
    Enum.concat(message, [{"event", event}])
  end

end
