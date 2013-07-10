defmodule Poxa.ChannelsHandler do

  require Lager
  alias Poxa.AuthorizationHelper
  alias Poxa.Subscription

  def init(_transport, req, _opts) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def allowed_methods(req, state) do
    {["GET"], req, state}
  end

  def is_authorized(req, channel) do
    AuthorizationHelper.is_authorized(req, channel)
  end

  def content_types_provided(req, state) do
    {[{{"application", "json", []}, :get_json}], req, state}
  end

  def get_json(req, state) do
    {channel, req} = :cowboy_req.binding(:channel_name, req)
    count = Subscription.subscription_count(channel)
    {JSEX.encode!(occupied: count > 0, subscription_count: count), req, nil}
  end

  def terminate(_reason, _req, _state), do: :ok
end
