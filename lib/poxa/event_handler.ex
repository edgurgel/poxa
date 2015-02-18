defmodule Poxa.EventHandler do
  @moduledoc """
  This module contains Cowboy HTTP handler callbacks to request on /apps/:app_id/events

  More info on Cowboy HTTP handler at: http://ninenines.eu/docs/en/cowboy/HEAD/guide/http_handlers

  More info on Pusher events at: http://pusher.com/docs/rest_api
  """
  alias Poxa.Authentication
  alias Poxa.PusherEvent
  alias Poxa.Event
  require Logger

  @error_json JSX.encode!(%{error: "invalid json"})
  @doc """
  If the body is a valid JSON, the state of the handler will be the body
  Otherwise the response will be a 400 status code
  """
  def init(_transport, _req, _opts), do: {:upgrade, :protocol, :cowboy_rest}

  def allowed_methods(req, state), do: {["POST"], req, state}

  @invalid_event_json JSX.encode!(%{error: "Event must have channel(s), name, and data"})
  def malformed_request(req, state) do
    {:ok, body, req} = :cowboy_req.body(req)
    case JSX.decode(body) do
      {:ok, data} ->
        if invalid_data?(data) do
          req = :cowboy_req.set_resp_body(@invalid_event_json, req)
          {true, req, state}
        else
          {false, req, %{body: body, data: data}}
        end
      _ ->
        req = :cowboy_req.set_resp_body(@invalid_event_json, req)
        {true, req, state}
    end
  end

  defp invalid_data?(%{"name" => _, "data" => _, "channel" => _}), do: false
  defp invalid_data?(%{"name" => _, "data" => _, "channels" => _}), do: false
  defp invalid_data?(_), do: true

  @authentication_error_json JSX.encode!(%{error: "Authentication error"})
  # http://pusher.com/docs/rest_api#authentication
  def is_authorized(req, %{body: body} = state) do
    {qs_vals, req} = :cowboy_req.qs_vals(req)
    {method, req} = :cowboy_req.method(req)
    {path, req} = :cowboy_req.path(req)
    authorized = Authentication.check(method, path, body, qs_vals) == :ok
    unless authorized do
      req = :cowboy_req.set_resp_body(@authentication_error_json, req)
    end
    {authorized, req, state}
  end

  @invalid_data_size_json JSX.encode!(%{error: "Data key must be smaller than 10KB"})
  def valid_entity_length(req, %{data: data} = state) do
    valid = byte_size(data["data"]) <= 10_000
    unless valid do
      req = :cowboy_req.set_resp_body(@invalid_data_size_json, req)
    end
    {valid, req, state}
  end

  def content_types_accepted(req, state) do
    {[{{"application", "json", :*}, :post}], req, state}
  end

  def content_types_provided(req, state) do
    {[{{"application", "json", []}, :undefined}], req, state}
  end

  def post(req, %{data: data}) do
    event = PusherEvent.build(data)
    PusherEvent.publish(event)
    Event.notify(:api_message, %{channels: event.channels, name: event.name})
    req = :cowboy_req.set_resp_body("{}", req)
    {true, req, nil}
  end
end
