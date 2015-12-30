defmodule Poxa.ChannelsHandler do
  @moduledoc """
  This module contains Cowboy HTTP handler callbacks to request on /apps/:app_id/channels[/:channel]

  More info on Pusher REST API at: http://pusher.com/docs/rest_api#channels
  """

  alias Poxa.AuthorizationHelper
  alias Poxa.Channel
  alias Poxa.PresenceChannel

  @doc false
  def init(_transport, _req, _opts) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  @doc false
  def allowed_methods(req, state) do
    {["GET"], req, state}
  end

  @valid_attributes ["user_count", "subscription_count"]

  @doc """
  A request is malformed on /channels if:

  * requesting invalid info (not user_count or subscription_count)
  * user_count for non-presence channels
  """
  def malformed_request(req, _state) do
    {info, req} = :cowboy_req.qs_val("info", req, "")
    attributes = String.split(info, ",")
      |> Enum.reject(&(&1 == ""))
    {channel, req} = :cowboy_req.binding(:channel_name, req, nil)
    {app_id, req} = :cowboy_req.binding(:app_id, req)
    if channel do
      {malformed_request_one_channel?(attributes, channel), req, {:one, app_id, channel, attributes}}
    else
      {filter, req} = :cowboy_req.qs_val("filter_by_prefix", req, nil)
      {malformed_request_all_channels?(attributes, filter), req, {:all, app_id, filter, attributes}}
    end
  end

  defp malformed_request_one_channel?(attributes, channel) do
    if Enum.all?(attributes, fn s -> Enum.member?(@valid_attributes, s) end) do
      !Channel.presence?(channel) and Enum.member?(attributes, "user_count")
    else
      true
    end
  end

  defp malformed_request_all_channels?(attributes, filter) do
    if Enum.all?(attributes, fn s -> Enum.member?(@valid_attributes, s) end) do
      if Enum.member?(attributes, "user_count") do
        !Channel.matches?(filter, "presence-")
      else
        false
      end
    else
      true
    end
  end

  @doc false
  def is_authorized(req, state) do
    AuthorizationHelper.is_authorized(req, state)
  end

  @doc false
  def content_types_provided(req, state) do
    {[{{"application", "json", []}, :get_json}], req, state}
  end

  @doc false
  def get_json(req, {:one, app_id, channel, attributes}) do
    show(app_id, channel, attributes, req, nil)
  end
  def get_json(req, {:all, app_id, filter, attributes}) do
    index(app_id, filter, attributes, req, nil)
  end

  defp show(app_id, channel, attributes, req, state) do
    occupied = Channel.occupied?(channel, app_id)
    attribute_list = mount_attribute_list(attributes, app_id, channel)
    {JSX.encode!([occupied: occupied] ++ attribute_list), req, state}
  end

  defp mount_attribute_list(attributes, app_id, channel) do
    attribute_list =
      if Enum.member?(attributes, "subscription_count") do
        [subscription_count: Channel.subscription_count(app_id, channel)]
      else
        []
      end
    attribute_list ++
      if Enum.member?(attributes, "user_count") do
        [user_count: PresenceChannel.user_count(app_id, channel)]
      else
        []
      end
  end

  defp index(app_id, filter, attributes, req, state) do
    channels = channels(app_id, filter, attributes)
    {JSX.encode!(channels: channels), req, state}
  end

  defp channels(app_id, filter, attributes) do
    for channel <- Channel.all(app_id), filter_channel(channel, filter) do
      {channel, mount_attribute_list(attributes, app_id, channel)}
    end
  end

  defp filter_channel(channel, nil), do: !Channel.private?(channel)
  defp filter_channel(channel, filter), do: Channel.matches?(channel, filter)
end
