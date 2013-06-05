defmodule Poxa.EventHandler do
  @moduledoc """
  This module contains Cowboy HTTP handler callbacks to request on /apps/:app_id/events

  More info on Cowboy HTTP handler at: http://ninenines.eu/docs/en/cowboy/HEAD/guide/http_handlers

  More info on Pusher events at: http://pusher.com/docs/rest_api
  """
  alias Poxa.Authentication
  alias Poxa.PusherEvent
  require Lager

  @error_json :jsx.encode([error: "invalid json"])
  @doc """
  If the body is a valid JSON, the state of the handler will be the body
  Otherwise the response will be a 400 status code
  """
  def init(_transport, req, _opts) do
    {:ok, body, req} = :cowboy_req.body(req)
    if :jsx.is_json(body) do
      {:ok, req, body}
    else
      Lager.info("Invalid JSON on Event Handler: #{body}")
      {:ok, req} = :cowboy_req.reply(400, [], @error_json, req)
      {:shutdown, req, nil}
    end
  end

  @doc """
  Decode the JSON and send events to channels if successful
  """
  def handle(req, body) do
    {qs_vals, req} = :cowboy_req.qs_vals(req)
    {path, req} = :cowboy_req.path(req)
    # http://pusher.com/docs/rest_api#authentication
    case Authentication.check(path,body, qs_vals) do
      :ok ->
        request_data = :jsx.decode(body)
        {request_data, channels, exclude} = PusherEvent.parse_channels(request_data)
        case channels do
          nil ->
            Lager.info('No channel defined')
            {:ok, req, nil}
          _ ->
            message = prepare_message(request_data)
            PusherEvent.send_message_to_channels(channels, message, exclude)
            {:ok, req} = :cowboy_req.reply(200, [], "{}", req)
            {:ok, req, nil}
        end
      _ ->
        Lager.info('Authentication failed')
        {:ok, req, nil}
    end
  end


  def content_types_accepted(req, state) do
    {[{{"application", "json", []}, :handle}], req, state}
  end

  def content_types_provided(req, state) do
    {[{{"application", "json", []}, :handle}], req, state}
  end

  def terminate(_reason, _req, _state), do: :ok

  # Remove name and add event to the response
  defp prepare_message(message) do
    {event, message} = ListDict.pop(message, "name")
    List.concat(message, [{"event", event}])
  end

end
