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
    if channel do
      {malformed_request_one_channel?(attributes, channel), req, {:one, channel, attributes}}
    else
      {filter, req} = :cowboy_req.qs_val("filter_by_prefix", req, nil)
      {malformed_request_all_channels?(attributes, filter), req, {:all, filter, attributes}}
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
  def get_json(req, {:one, channel, attributes}) do
    show(channel, attributes, req, nil)
  end
  def get_json(req, {:all, filter, attributes}) do
    index(filter, attributes, req, nil)
  end

  defp show(channel, attributes, req, state) do
    occupied = Channel.occupied?(channel)
    attribute_list = mount_attribute_list(attributes, channel)
    {Poison.encode!(Map.merge(%{occupied: occupied}, attribute_list)), req, state}
  end

  defp mount_attribute_list(attributes, channel) do
    attributes_data =
      if Enum.member?(attributes, "subscription_count") do
        %{subscription_count: Channel.subscription_count(channel)}
      else
        %{}
      end
      if Enum.member?(attributes, "user_count") do
        Map.put(attributes_data, :user_count, PresenceChannel.user_count(channel))
      else
        attributes_data
      end
  end

  defp index(filter, attributes, req, state) do
    channels = channels(filter, attributes)
    {Poison.encode!(%{:channels => channels}), req, state}
  end

  defp channels(filter, attributes) do
    for channel <- Channel.all, filter_channel(channel, filter), into: %{} do
      {channel, mount_attribute_list(attributes, channel)}
    end
  end

  defp filter_channel(channel, nil), do: !Channel.private?(channel)
  defp filter_channel(channel, filter), do: Channel.matches?(channel, filter)
end
