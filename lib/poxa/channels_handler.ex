defmodule Poxa.ChannelsHandler do
  @moduledoc """
  This module contains Cowboy HTTP handler callbacks to request on /apps/:app_id/channels[/:channel]

  More info on Pusher REST API at: http://pusher.com/docs/rest_api#channels
  """

  alias Poxa.AuthorizationHelper
  alias Poxa.Channel
  alias Poxa.PresenceChannel

  def init(_transport, _req, _opts) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def allowed_methods(req, state) do
    {["GET"], req, state}
  end

  @valid_attributes ["user_count", "subscription_count"]

  def malformed_request(req, _state) do
    {info, req} = :cowboy_req.qs_val("info", req, "")
    attributes = String.split(info, ",")
    {channel, req} = :cowboy_req.binding(:channel_name, req, nil)
    if channel do
      {malformed_request_one_channel?(attributes, channel), req, {channel, attributes}}
    else
      {false, req, nil}
    end
  end

  defp malformed_request_one_channel?(attributes, channel) do
    if Enum.all?(attributes, fn s -> Enum.member?(@valid_attributes, s) end) do
      !Channel.presence?(channel) and Enum.member?(attributes, "user_count")
    else
      true
    end
  end

  def is_authorized(req, state) do
    AuthorizationHelper.is_authorized(req, state)
  end

  def content_types_provided(req, state) do
    {[{{"application", "json", []}, :get_json}], req, state}
  end

  def get_json(req, {channel, attributes}) do
    show(channel, attributes, req, nil)
  end
  def get_json(req, nil) do
    index(req, nil)
  end

  defp show(channel, attributes, req, state) do
    occupied = Channel.occupied?(channel)
    attribute_list = mount_attribute_list(attributes, channel)
    {JSEX.encode!([occupied: occupied] ++ attribute_list), req, state}
  end

  defp mount_attribute_list(attributes, channel) do
    attribute_list =
      if Enum.member?(attributes, "subscription_count") do
        [subscription_count: Channel.subscription_count(channel)]
      else
        []
      end
    attribute_list ++
      if Enum.member?(attributes, "user_count") do
        [user_count: PresenceChannel.user_count(channel)]
      else
        []
      end
  end

  defp index(req, state) do
    {filter, req} = :cowboy_req.qs_val("filter_by_prefix", req, "")
    channels = channels(filter)
    {JSEX.encode!(channels: channels), req, state}
  end

  defp channels(filter) do
    Channel.all
      |> Enum.filter_map(
        fn channel ->
          filter_channel(channel, filter)
        end,
        fn channel ->
          {channel, Channel.presence?(channel) }
        end)
      |> Enum.map(&user_count/1)
  end

  defp filter_channel(channel, nil), do: ! Channel.private?(channel)
  defp filter_channel(channel, filter), do: Channel.matches?(channel, filter)

  defp user_count({channel, true}), do: { channel, user_count: PresenceChannel.user_count(channel) }
  defp user_count({channel, false}), do: { channel, user_count: Channel.subscription_count(channel) }

end
