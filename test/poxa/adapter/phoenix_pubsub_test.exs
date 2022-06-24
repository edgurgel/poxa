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

  describe "subscription_count/1" do
    test "count total subscriptions" do
      execution = fn ->
        receive do
          _ -> :ok
        end
      end

      spawn_registered("channel1", execution)
      spawn_registered("channel1", execution)

      assert subscription_count("channel1") == 2
    end
  end

  describe "subscription_count/2" do
    test "count subscriptions per pid" do
      execution = fn ->
        receive do
          _ -> :ok
        end
      end

      child1 = spawn_registered(["channel1", "channel2"], execution)
      child2 = spawn_registered("channel1", execution)

      assert subscription_count("channel1", child1) == 1
      assert subscription_count("channel1", child2) == 1
      assert subscription_count("channel1", self()) == 0
      assert subscription_count("unknown_channel", child1) == 0
    end

    test "count number of subscription with a user id" do
      execution = fn ->
        receive do
          _ -> :ok
        end
      end

      spawn_registered("channel", execution, %{user_id: "user1", user_info: "user1 info"})

      spawn_registered("channel", execution, %{
        user_id: "user1",
        user_info: "different user1 info"
      })

      spawn_registered("channel", execution, %{user_id: "user2", user_info: "user2 info"})

      assert subscription_count("channel", "user1") == 2
      assert subscription_count("channel", "user2") == 1
      assert subscription_count("channel", "user3") == 0
      assert subscription_count("unknown_channel", "user1") == 0
    end
  end

  describe "presence_subscriptions/1" do
    test "presence_subscriptions" do
      register!("presence-channel1", %{user_id: "user123", user_info: "userinfo"})
      register!("presence-channel2", %{user_id: "user234", user_info: "userinfo"})

      assert presence_subscriptions(self()) == [
               {"presence-channel1", "user123"},
               {"presence-channel2", "user234"}
             ]
    end
  end

  defp spawn_registered(channels, execution, value \\ nil) do
    parent = self()
    channels = List.wrap(channels)

    child =
      spawn_link(fn ->
        for channel <- channels do
          if value do
            register!(channel, value)
          else
            register!(channel)
          end
        end

        send(parent, {self(), :registered})
        execution.()
      end)

    assert_receive {^child, :registered}
    child
  end
end
