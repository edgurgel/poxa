defmodule Poxa.UsersHandler do
  @moduledoc """
  This module contains Cowboy HTTP handler callbacks to request on /apps/:app_id/channels/:channel/users

  More info on Pusher REST API at: http://pusher.com/docs/rest_api
  """

  alias Poxa.AuthorizationHelper
  alias Poxa.PresenceChannel
  alias Poxa.Channel

  def init(_transport, _req, _opts) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def allowed_methods(req, state) do
    {["GET"], req, state}
  end

  def malformed_request(req, _state) do
    {channel, req} = :cowboy_req.binding(:channel_name, req)
    {!Channel.presence?(channel), req, channel}
  end

  def is_authorized(req, channel) do
    AuthorizationHelper.is_authorized(req, channel)
  end

  def content_types_provided(req, state) do
    {[{{"application", "json", []}, :get_json}], req, state}
  end

  @doc """
  Fetch user ids currently subscribed to a presence channel

      {
        "users": [
          { "id": "user1" },
          { "id": "user2" }
        ]
      }

  """
  def get_json(req, channel) do
    response = PresenceChannel.users(channel) |> Enum.map(fn(id) -> [id: id] end)
    {JSX.encode!(users: response), req, nil}
  end
end

