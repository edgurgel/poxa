defmodule Poxa.ChannelsHandlerTest do
  use ExUnit.Case, async: true
  alias Poxa.Channel
  alias Poxa.PresenceChannel
  import Mimic
  import Poxa.ChannelsHandler

  setup :verify_on_exit!

  setup do
    stub(Poison)
    stub(:cowboy_req)
    :ok
  end

  test "malformed_request on multiple channels with no attributes" do
    expect(:cowboy_req, :qs_val, fn "info", :req, "" -> {"", :req2} end)
    expect(:cowboy_req, :binding, fn :channel_name, :req2, nil -> {:nil, :req3} end)
    expect(:cowboy_req, :qs_val, fn "filter_by_prefix", :req3, nil -> {nil, :req4} end)

    assert malformed_request(:req, :state) == {false, :req4, {:all, nil, []}}
  end

  test "malformed_request on multiple channels with valid attributes" do
    expect(:cowboy_req, :qs_val, fn "info", :req, "" -> {"subscription_count", :req2} end)
    expect(:cowboy_req, :binding, fn :channel_name, :req2, nil -> {:nil, :req3} end)
    expect(:cowboy_req, :qs_val, fn "filter_by_prefix", :req3, nil -> {nil, :req4} end)

    assert malformed_request(:req, :state) == {false, :req4, {:all, nil, ["subscription_count"]}}
  end

  test "malformed_request on multiple channels with invalid attributes" do
    expect(:cowboy_req, :qs_val, fn "info", :req, "" -> {"user_count", :req2} end)
    expect(:cowboy_req, :binding, fn :channel_name, :req2, nil -> {:nil, :req3} end)
    expect(:cowboy_req, :qs_val, fn "filter_by_prefix", :req3, nil -> {nil, :req4} end)

    assert malformed_request(:req, :state) == {true, :req4, {:all, nil, ["user_count"]}}
  end

  test "malformed_request on multiple channels with filter" do
    expect(:cowboy_req, :qs_val, fn "info", :req, "" -> {"", :req2} end)
    expect(:cowboy_req, :binding, fn :channel_name, :req2, nil -> {:nil, :req3} end)
    expect(:cowboy_req, :qs_val, fn "filter_by_prefix", :req3, nil -> {"poxa-", :req4} end)

    assert malformed_request(:req, :state) == {false, :req4, {:all, "poxa-", []}}
  end

  test "malformed_request on multiple channels with presence filter and user_count attribute" do

    expect(:cowboy_req, :qs_val, fn "info", :req, "" -> {"user_count", :req2} end)
    expect(:cowboy_req, :binding, fn :channel_name, :req2, nil -> {:nil, :req3} end)
    expect(:cowboy_req, :qs_val, fn "filter_by_prefix", :req3, nil -> {"presence-", :req4} end)

    assert malformed_request(:req, :state) == {false, :req4, {:all, "presence-", ["user_count"]}}
  end

  test "malformed_request on single channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, fn "info", :req, "" -> {"subscription_count,message_count", :req2} end)
    expect(:cowboy_req, :binding, fn :channel_name, :req2, nil -> {"channel", :req3} end)

    assert malformed_request(:req, :state) == {true, :req3, {:one, "channel", ["subscription_count", "message_count"]}}
  end

  test "malformed_request on single channel with invalid attribute" do
    expect(:cowboy_req, :qs_val, fn "info", :req, "" -> {"message_count", :req2} end)
    expect(:cowboy_req, :binding, fn :channel_name, :req2, nil -> {"channel", :req3} end)

    assert malformed_request(:req, :state) == {true, :req3, {:one, "channel", ["message_count"]}}
  end

  test "malformed_request on single channel with valid attributes" do
    expect(:cowboy_req, :qs_val, fn "info", :req, "" -> {"subscription_count", :req2} end)
    expect(:cowboy_req, :binding, fn :channel_name, :req2, nil -> {"channel", :req3} end)

    assert malformed_request(:req, :state) == {false, :req3, {:one, "channel", ["subscription_count"]}}
  end

  test "malformed_request on single non presence-channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, fn "info", :req, "" -> {"user_count", :req2} end)
    expect(:cowboy_req, :binding, fn :channel_name, :req2, nil -> {"channel", :req3} end)

    assert malformed_request(:req, :state) == {true, :req3, {:one, "channel", ["user_count"]}}
  end

  test "malformed_request on single presence-channel with invalid attributes" do
    expect(:cowboy_req, :qs_val, fn "info", :req, "" -> {"user_count,subscription_count", :req2} end)
    expect(:cowboy_req, :binding, fn :channel_name, :req2, nil -> {"presence-channel", :req3} end)

    assert malformed_request(:req, :state) == {false, :req3, {:one, "presence-channel", ["user_count", "subscription_count"]}}
  end

  test "get_json on a specific channel with subscription_count attribute" do
    expect(Channel, :occupied?, fn "channel" -> true end)
    expect(Channel, :subscription_count, fn "channel" -> 5 end)
    expected = %{:occupied => true, :subscription_count => 5}
    expect(Poison, :encode!, fn ^expected -> :encoded_json end)

    assert get_json(:req, {:one, "channel", ["subscription_count"]}) == {:encoded_json, :req, nil}
  end

  test "get_json on a specific channel with user_count attribute" do
    expect(Channel, :occupied?, fn "presence-channel" -> true end)
    expect(PresenceChannel, :user_count, fn "presence-channel" -> 3 end)
    expected = %{:occupied => true, :user_count => 3}
    expect(Poison, :encode!, fn ^expected -> :encoded_json end)

    assert get_json(:req, {:one, "presence-channel", ["user_count"]}) == {:encoded_json, :req, nil}
  end

  test "get_json on a specific channel with user_count and subscription_count attributes" do
    expect(Channel, :occupied?, fn "presence-channel" -> true end)
    expect(PresenceChannel, :user_count, fn "presence-channel" -> 3 end)
    expect(Channel, :subscription_count, fn "presence-channel" -> 5 end)
    expected = %{occupied: true, subscription_count: 5, user_count: 3}
    expect(Poison, :encode!, fn ^expected -> :encoded_json end)

    assert get_json(:req, {:one, "presence-channel", ["subscription_count", "user_count"]}) == {:encoded_json, :req, nil}
  end

  test "get_json on every single channel" do
    expect(Channel, :all, fn -> ["presence-channel", "private-channel"] end)
    expect(PresenceChannel, :user_count, fn "presence-channel" -> 3 end)
    expected = %{channels: %{"presence-channel" => %{user_count: 3}}}
    expect(Poison, :encode!, fn ^expected -> :encoded_json end)

    assert get_json(:req, {:all, nil, ["user_count"]}) == {:encoded_json, :req, nil}
  end

  test "get_json on every single channel with filter" do
    expect(Channel, :all, fn -> ["presence-channel", "poxa-channel"] end)
    expected = %{channels:  %{"poxa-channel" => %{}}}
    expect(Poison, :encode!, fn ^expected -> :encoded_json end)

    assert get_json(:req, {:all, "poxa-", []}) == {:encoded_json, :req, nil}
  end
end
