defmodule Poxa.UsersHandlerTest do
  use ExUnit.Case, async: true
  alias Poxa.PresenceChannel
  use Mimic
  import Poxa.UsersHandler

  setup do
    stub(Jason)
    stub(PresenceChannel)
    stub(:cowboy_req)
    :ok
  end

  describe "malformed_request/2" do
    test "malformed_request returns false if we have a presence channel" do
      expect(:cowboy_req, :binding, fn :channel_name, :req -> "presence-channel" end)

      assert malformed_request(:req, :state) == {false, :req, "presence-channel"}
    end

    test "malformed_request returns true if we don't have a presence channel" do
      expect(:cowboy_req, :binding, fn :channel_name, :req -> "private-channel" end)

      assert malformed_request(:req, :state) == {true, :req, "private-channel"}
    end
  end

  test "get_json returns users of a presence channel" do
    expect(PresenceChannel, :users, fn "presence-channel" -> ["user1", "user2"] end)
    expected = %{users: [%{id: "user1"}, %{id: "user2"}]}
    expect(Jason, :encode!, fn ^expected -> :encoded_json end)

    assert get_json(:req, "presence-channel") == {:encoded_json, :req, nil}
  end
end
