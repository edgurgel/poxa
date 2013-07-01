defmodule Poxa.UsersHandler do
  @moduledoc """
  This module contains Cowboy HTTP handler callbacks to request on /apps/:app_id/channels/:channel/users

  More info on Pusher REST API at: http://pusher.com/docs/rest_api
  """

  require Lager
  alias Poxa.PresenceSubscription
  alias Poxa.Authentication

  def init(_transport, req, _opts) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def allowed_methods(req, state) do
    {["GET"], req, state}
  end

  def malformed_request(req, state) do
    {channel, req} = :cowboy_req.binding(:channel_name, req)
    {!PresenceSubscription.presence_channel?(channel), req, channel}
  end

  def is_authorized(req, channel) do
    {:ok, body, req} = :cowboy_req.body(req)
    {method, req} = :cowboy_req.method(req)
    {qs_vals, req} = :cowboy_req.qs_vals(req)
    {path, req} = :cowboy_req.path(req)
    auth = Authentication.check(method, path, body, qs_vals)
    if auth == :ok do
      {true, req, channel}
    else
      {{false, "authentication failed"}, req, nil}
    end
  end

  def content_types_provided(req, state) do
    {[{{"application", "json", []}, :get_json}], req, state}
  end

  def get_json(req, channel) do
    response = PresenceSubscription.users(channel)
      |> Enum.map(fn(id) -> [{"id", id}] end)
    {JSEX.encode!(users: response), req, response}
  end

  def terminate(_reason, _req, _state), do: :ok
end

