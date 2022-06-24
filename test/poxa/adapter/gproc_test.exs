defmodule Poxa.Adapter.GProcTest do
  use ExUnit.Case, async: true

  import Poxa.Adapter.GProc

  setup do
    Application.start(:gproc)
    on_exit(fn -> Application.stop(:gproc) end)
    :ok
  end

  describe "register!/1,2" do
    test "register a property without value" do
      register!(:property)
      assert :gproc.get_value({:p, :l, {:pusher, :property}})
    end

    test "register a property with a value" do
      register!(:property, :value)
      assert :gproc.get_value({:p, :l, {:pusher, :property}}) == :value
    end
  end

  describe "unregister/1" do
    test "unregister a property" do
      :gproc.reg({:p, :l, {:pusher, :property}})
      unregister!(:property)

      assert_raise ArgumentError, fn ->
        assert :gproc.get_value({:p, :l, {:pusher, :property}})
      end
    end
  end

  describe "send!/3" do
    test "send message to registered processes" do
      parent = self()

      child =
        spawn_registered("channel", fn ->
          receive do
            {^parent, msg} ->
              send(parent, {self(), msg})
          end
        end)

      send!(:msg, "channel", self())
      assert_receive {^child, :msg}
    end

    test "send message to registered processes with socket_id" do
      parent = self()

      child =
        spawn_registered("channel", fn ->
          receive do
            {^parent, msg, socket_id} ->
              send(parent, {self(), msg, socket_id})
          end
        end)

      send!(:msg, "channel", self(), :socket_id)
      assert_receive {^child, :msg, :socket_id}
    end
  end

  describe "subscription_count/1,2" do
    test "count subscriptions for pid" do
      execution = fn ->
        receive do
          _ -> :ok
        end
      end

      child1 = spawn_registered("channel1", execution)
      child2 = spawn_registered("channel1", execution)

      assert subscription_count("channel1") == 2
      assert subscription_count("channel1", child1) == 1
      assert subscription_count("channel1", child2) == 1
    end

    test "subscription_count" do
      execution = fn ->
        receive do
          _ -> :ok
        end
      end

      spawn_registered("channel", execution, {"user1", "user1 info"})
      spawn_registered("channel", execution, {"user1", "different user1 info"})
      spawn_registered("channel", execution, {"user2", "user2 info"})

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

  describe "channels" do
    test "list channels processes are registered to" do
      execution = fn ->
        receive do
          _ -> :ok
        end
      end

      spawn_registered("channel1", execution)
      spawn_registered("channel2", execution)

      assert channels() == ["channel1", "channel2"]
    end
  end

  describe "unique_subscriptions/1" do
    test "unique_subscriptions" do
      execution = fn ->
        receive do
          _ -> :ok
        end
      end

      spawn_registered("channel", execution, {"user1", "user1 info"})
      spawn_registered("channel", execution, {"user1", "different user1 info"})
      spawn_registered("channel", execution, {"user2", "user2 info"})

      %{"user1" => "different user1 info", "user2" => "user2 info"} =
        unique_subscriptions("channel")
    end
  end

  describe "fetch/1" do
    test "fetch with no previous value" do
      assert_raise ArgumentError, fn ->
        fetch(:property) == :undefined
      end
    end

    test "fetch with property without previous value" do
      :gproc.reg({:p, :l, {:pusher, :property}})
      assert fetch(:property) == :undefined
    end

    test "fetch with property with previous value" do
      :gproc.reg({:p, :l, {:pusher, :property}}, :value)
      assert fetch(:property) == :value
    end
  end

  defp spawn_registered(channel, execution, value \\ nil) do
    parent = self()

    child =
      spawn_link(fn ->
        if value do
          register!(channel, value)
        else
          register!(channel)
        end

        send(parent, {self(), :registered})
        execution.()
      end)

    assert_receive {^child, :registered}
    child
  end
end
