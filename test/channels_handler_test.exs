defmodule Poxa.ChannelsHandlerTest do
  use ExUnit.Case, async: true
  alias Poxa.Channel
  alias Poxa.PresenceChannel
  use Mimic
  import Poxa.ChannelsHandler

  setup do
    stub(Jason)
    stub(:cowboy_req)
    :ok
  end

  describe "malformed_request/2" do
    test "multiple channels with no attributes" do
      expect(:cowboy_req, :parse_qs, fn :req -> [] end)
      expect(:cowboy_req, :binding, fn :channel_name, :req, nil -> nil end)
      assert malformed_request(:req, :state) == {false, :req, {:all, nil, []}}
    end

    test "multiple channels with valid attributes" do
      expect(:cowboy_req, :parse_qs, fn :req -> [{"info", "subscription_count"}] end)
      expect(:cowboy_req, :binding, fn :channel_name, :req, nil -> nil end)

      assert malformed_request(:req, :state) == {false, :req, {:all, nil, ["subscription_count"]}}
    end

    test "multiple channels with invalid attributes" do
      expect(:cowboy_req, :parse_qs, fn :req -> [{"info", "user_count"}] end)
      expect(:cowboy_req, :binding, fn :channel_name, :req, nil -> nil end)

      assert malformed_request(:req, :state) == {true, :req, {:all, nil, ["user_count"]}}
    end

    test "multiple channels with filter" do
      expect(:cowboy_req, :parse_qs, fn :req -> [{"filter_by_prefix", "poxa-"}] end)
      expect(:cowboy_req, :binding, fn :channel_name, :req, nil -> nil end)

      assert malformed_request(:req, :state) == {false, :req, {:all, "poxa-", []}}
    end

    test "multiple channels with presence filter and user_count attribute" do
      expect(:cowboy_req, :parse_qs, fn :req ->
        [{"info", "user_count"}, {"filter_by_prefix", "presence-"}]
      end)

      expect(:cowboy_req, :binding, fn :channel_name, :req, nil -> nil end)

      assert malformed_request(:req, :state) == {false, :req, {:all, "presence-", ["user_count"]}}
    end

    test "single channel with invalid attributes" do
      expect(:cowboy_req, :parse_qs, fn :req ->
        [{"info", "subscription_count,message_count"}, {"filter_by_prefix", "presence-"}]
      end)

      expect(:cowboy_req, :binding, fn :channel_name, :req, nil -> "channel" end)

      assert malformed_request(:req, :state) ==
               {true, :req, {:one, "channel", ["subscription_count", "message_count"]}}
    end

    test "single channel with invalid attribute" do
      expect(:cowboy_req, :parse_qs, fn :req -> [{"info", "message_count"}] end)
      expect(:cowboy_req, :binding, fn :channel_name, :req, nil -> "channel" end)

      assert malformed_request(:req, :state) == {true, :req, {:one, "channel", ["message_count"]}}
    end

    test "single channel with valid attributes" do
      expect(:cowboy_req, :parse_qs, fn :req -> [{"info", "subscription_count"}] end)
      expect(:cowboy_req, :binding, fn :channel_name, :req, nil -> "channel" end)

      assert malformed_request(:req, :state) ==
               {false, :req, {:one, "channel", ["subscription_count"]}}
    end

    test "single non presence-channel with invalid attributes" do
      expect(:cowboy_req, :parse_qs, fn :req -> [{"info", "user_count"}] end)
      expect(:cowboy_req, :binding, fn :channel_name, :req, nil -> "channel" end)

      assert malformed_request(:req, :state) == {true, :req, {:one, "channel", ["user_count"]}}
    end

    test "single presence-channel with invalid attributes" do
      expect(:cowboy_req, :parse_qs, fn :req -> [{"info", "user_count,subscription_count"}] end)
      expect(:cowboy_req, :binding, fn :channel_name, :req, nil -> "presence-channel" end)

      assert malformed_request(:req, :state) ==
               {false, :req, {:one, "presence-channel", ["user_count", "subscription_count"]}}
    end
  end

  describe "get_json/2" do
    test "a specific channel with subscription_count attribute" do
      expect(Channel, :occupied?, fn "channel" -> true end)
      expect(Channel, :subscription_count, fn "channel" -> 5 end)
      expected = %{:occupied => true, :subscription_count => 5}
      expect(Jason, :encode!, fn ^expected -> :encoded_json end)

      assert get_json(:req, {:one, "channel", ["subscription_count"]}) ==
               {:encoded_json, :req, nil}
    end

    test "a specific channel with user_count attribute" do
      expect(Channel, :occupied?, fn "presence-channel" -> true end)
      expect(PresenceChannel, :user_count, fn "presence-channel" -> 3 end)
      expected = %{:occupied => true, :user_count => 3}
      expect(Jason, :encode!, fn ^expected -> :encoded_json end)

      assert get_json(:req, {:one, "presence-channel", ["user_count"]}) ==
               {:encoded_json, :req, nil}
    end

    test "a specific channel with user_count and subscription_count attributes" do
      expect(Channel, :occupied?, fn "presence-channel" -> true end)
      expect(PresenceChannel, :user_count, fn "presence-channel" -> 3 end)
      expect(Channel, :subscription_count, fn "presence-channel" -> 5 end)
      expected = %{occupied: true, subscription_count: 5, user_count: 3}
      expect(Jason, :encode!, fn ^expected -> :encoded_json end)

      assert get_json(:req, {:one, "presence-channel", ["subscription_count", "user_count"]}) ==
               {:encoded_json, :req, nil}
    end

    test "every single channel" do
      expect(Channel, :all, fn -> ["presence-channel", "private-channel"] end)
      expect(PresenceChannel, :user_count, fn "presence-channel" -> 3 end)
      expected = %{channels: %{"presence-channel" => %{user_count: 3}}}
      expect(Jason, :encode!, fn ^expected -> :encoded_json end)

      assert get_json(:req, {:all, nil, ["user_count"]}) == {:encoded_json, :req, nil}
    end

    test "every single channel with filter" do
      expect(Channel, :all, fn -> ["presence-channel", "poxa-channel"] end)
      expected = %{channels: %{"poxa-channel" => %{}}}
      expect(Jason, :encode!, fn ^expected -> :encoded_json end)

      assert get_json(:req, {:all, "poxa-", []}) == {:encoded_json, :req, nil}
    end
  end
end
