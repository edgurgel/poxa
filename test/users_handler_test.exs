defmodule Poxa.UsersHandlerTest do
  use ExUnit.Case, async: true
  alias Poxa.PresenceChannel
  import Mimic
  import Poxa.UsersHandler

  setup :verify_on_exit!

  setup do
    stub(Poison)
    stub(PresenceChannel)
    stub(:cowboy_req)
    :ok
  end

  test "malformed_request returns false if we have a presence channel" do
    expect(:cowboy_req, :binding, fn :channel_name, :req -> {"presence-channel", :req} end)

    assert malformed_request(:req, :state) == {false, :req, "presence-channel"}
  end

  test "malformed_request returns true if we don't have a presence channel" do
    expect(:cowboy_req, :binding, fn :channel_name, :req -> {"private-channel", :req} end)

    assert malformed_request(:req, :state) == {true, :req, "private-channel"}
  end

  test "get_json returns users of a presence channel" do
    expect(PresenceChannel, :users, fn "presence-channel" -> ["user1", "user2"] end)
    expected = %{ users: [%{ id: "user1" }, %{ id: "user2" }] }
    expect(Poison, :encode!, fn ^expected -> :encoded_json end)

    assert get_json(:req, "presence-channel") == {:encoded_json, :req, nil}
  end
end
