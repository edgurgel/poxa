defmodule Poxa.SubscriptionTest do
  use ExUnit.Case, async: true
  alias Poxa.AuthSignature
  alias Poxa.PresenceSubscription
  alias Poxa.Channel
  alias Poxa.PusherEvent
  use Mimic
  import Poxa.Subscription

  setup do
    stub(Poxa.registry())
    stub(AuthSignature)
    stub(PresenceSubscription)
    stub(PusherEvent)
    :ok
  end

  test "subscription to a public channel" do
    expect(Channel, :member?, fn _, _ -> false end)
    expect(Poxa.registry(), :register!, fn _ -> :registered end)
    assert subscribe!(%{"channel" => "public-channel"}, nil) == {:ok, "public-channel"}
  end

  test "subscription to a missing channel name" do
    expect(PusherEvent, :pusher_error, fn _ -> :error_message end)

    assert subscribe!(%{}, nil) == {:error, :error_message}
  end

  test "subscription to a public channel but already subscribed" do
    pid = self()
    expect(Channel, :member?, fn "public-channel", ^pid -> true end)
    assert subscribe!(%{"channel" => "public-channel"}, nil) == {:ok, "public-channel"}
  end

  test "subscription to a private channel" do
    pid = self()
    expect(Channel, :member?, fn "private-channel", ^pid -> false end)
    expect(Poxa.registry(), :register!, fn _ -> :registered end)
    expect(AuthSignature, :valid?, fn _, _ -> true end)

    assert subscribe!(
             %{"channel" => "private-channel", "auth" => "signeddata"},
             "SocketId"
           ) == {:ok, "private-channel"}
  end

  test "subscription to a private channel having a channel_data" do
    pid = self()
    expect(Channel, :member?, fn "private-channel", ^pid -> false end)
    expect(Poxa.registry(), :register!, fn _ -> :registered end)
    expect(AuthSignature, :valid?, fn _, _ -> true end)

    assert subscribe!(
             %{
               "channel" => "private-channel",
               "auth" => "signeddata",
               "channel_data" => "{\"user_id\" : \"id123\", \"user_info\" : \"info456\"}"
             },
             "SocketId"
           ) == {:ok, "private-channel"}
  end

  test "subscription to a presence channel" do
    expect(AuthSignature, :valid?, fn _, _ -> true end)
    expect(PresenceSubscription, :subscribe!, fn _, _ -> :ok end)

    assert subscribe!(
             %{
               "channel" => "presence-channel",
               "auth" => "signeddata",
               "channel_data" => "{\"user_id\" : \"id123\", \"user_info\" : \"info456\""
             },
             "SocketId"
           ) == :ok
  end

  test "subscription to a private-channel having bad authentication" do
    expect(AuthSignature, :valid?, fn _, _ -> false end)
    expect(PusherEvent, :pusher_error, fn _ -> :error_message end)

    assert subscribe!(
             %{"channel" => "private-channel", "auth" => "signeddate"},
             "SocketId"
           ) == {:error, :error_message}
  end

  test "subscription to a presence-channel having bad authentication" do
    expect(AuthSignature, :valid?, fn _, _ -> false end)
    expect(PusherEvent, :pusher_error, fn _ -> :error_message end)

    assert subscribe!(
             %{"channel" => "presence-channel", "auth" => "signeddate"},
             "SocketId"
           ) == {:error, :error_message}
  end

  test "unsubscribe channel being subscribed" do
    pid = self()
    expect(Channel, :member?, fn "a_channel", ^pid -> true end)
    expect(Poxa.registry(), :unregister!, fn _ -> :ok end)

    assert unsubscribe!(%{"channel" => "a_channel"}) == {:ok, "a_channel"}
  end

  test "unsubscribe channel being not subscribed" do
    pid = self()
    expect(Channel, :member?, fn "a_channel", ^pid -> false end)

    assert unsubscribe!(%{"channel" => "a_channel"}) == {:ok, "a_channel"}
  end

  test "unsubscribe from a presence channel" do
    pid = self()
    expect(Channel, :member?, fn "presence-channel", ^pid -> true end)

    expect(PresenceSubscription, :unsubscribe!, fn "presence-channel" ->
      {:ok, "presence-channel"}
    end)

    expect(Poxa.registry(), :unregister!, fn "presence-channel" -> :ok end)

    assert unsubscribe!(%{"channel" => "presence-channel"}) == {:ok, "presence-channel"}
  end
end
