defmodule Poxa.ChannelsHandler do
  @moduledoc """
  This module contains Cowboy HTTP handler callbacks to request on /apps/:app_id/channels[/:channel]

  More info on Pusher REST API at: http://pusher.com/docs/rest_api
  """

  require Lager
  alias Poxa.AuthorizationHelper
  alias Poxa.Subscription

  def init(_transport, req, _opts) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def allowed_methods(req, state) do
    {["GET"], req, state}
  end

  def is_authorized(req, state) do
    AuthorizationHelper.is_authorized(req, state)
  end

  def content_types_provided(req, state) do
    {[{{"application", "json", []}, :get_json}], req, state}
  end

  def get_json(req, state) do
    {channel, req} = :cowboy_req.binding(:channel_name, req)
    count = Subscription.subscription_count(channel)
    {JSEX.encode!(occupied: count > 0, subscription_count: count), req, nil}
  end

end
