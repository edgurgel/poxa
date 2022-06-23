defmodule Poxa.Adapter.PhoenixPubSubTest do
  use ExUnit.Case, async: true
  import Poxa.Adapter.PhoenixPubSub
  alias Poxa.Adapter.PhoenixPubSub
  alias Phoenix.PubSub
  alias Phoenix.Tracker

  setup do
    start_supervised!(Poxa.Adapter.PhoenixPubSub.Supervisor)
    :ok
  end

  describe "register!/1,2" do
    test "registering a property" do
      assert :ok = register!("mychannel")

      assert Registry.lookup(PhoenixPubSub.Registry, {:pusher, "mychannel"}) == [{self(), nil}]

      assert [{"mychannel", _}] = Tracker.list(PhoenixPubSub.Tracker, "pusher:mychannel")

      assert PubSub.broadcast!(PhoenixPubSub.PubSub, "pusher:mychannel", :message)
      assert_receive :message
    end

    test "registering a property and a value" do
      assert :ok = register!("mychannel", %{my: "value"})

      assert Registry.lookup(PhoenixPubSub.Registry, {:pusher, "mychannel"}) == [
               {self(), %{my: "value"}}
             ]

      assert [{"mychannel", %{my: "value"}}] =
               Tracker.list(PhoenixPubSub.Tracker, "pusher:mychannel")

      assert PubSub.broadcast!(PhoenixPubSub.PubSub, "pusher:mychannel", :message)
      assert_receive :message
    end
  end

  describe "unregister!/1" do
  end

  describe "send!/3,4" do
  end
end
