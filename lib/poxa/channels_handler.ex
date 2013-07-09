defmodule Poxa.ChannelsHandler do

  require Lager
  alias Poxa.Authentication
  alias Poxa.PresenceSubscription
  alias Poxa.Subscription

  def init(_transport, req, _opts) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def allowed_methods(req, state) do
    {["GET"], req, state}
  end

  # Please, extract me to a handler helper. I'm a clone of another code at UsersHandler
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
    {channel, req} = :cowboy_req.binding(:channel_name, req)
    count = Subscription.subscription_count(channel)
    {JSEX.encode!(occupied: count > 0, subscription_count: count), req, nil}
  end

  def terminate(_reason, _req, _state), do: :ok
end
