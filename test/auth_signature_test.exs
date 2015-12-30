defmodule Poxa.AuthSignatureTest do
  use ExUnit.Case
  alias Poxa.Authentication
  alias Poxa.App
  import :meck
  import Poxa.AuthSignature

  setup do
    new Authentication
    new App
    on_exit fn -> unload end
    :ok
  end

  test "a valid signature" do
    expect(App, :key_secret, [{["app_id"], {:ok, {"app_key", "secret"}}}])
    signature = Poxa.CryptoHelper.hmac256_to_string("secret", "SocketId:private-channel")
    auth = "app_key:#{signature}"

    assert valid?("app_id", "SocketId:private-channel", auth)

    assert validate Authentication
    assert validate App
  end

  test "an inexisting app" do
    expect(App, :key_secret, [{["app_id"], {:error, :reason}}])

    refute valid?("app_id", "SocketId:private-channel", "Auth:key")

    assert validate Authentication
  end

  test "a different app_key" do
    expect(App, :key_secret, [{["app_id"], {:ok, {"app_key", "secret"}}}])
    signature = Poxa.CryptoHelper.hmac256_to_string("secret", "SocketId:private-channel")
    auth = "app_key2:#{signature}"

    refute valid?("app_id", "SocketId:private-channel", auth)

    assert validate Authentication
  end

  test "invalid auth string" do
    expect(App, :key_secret, [{["app_id"], {:ok, {"app_key", "secret"}}}])

    refute valid?("app_id", "SocketId:private-channel", "asdfasdf")

    assert validate Authentication
  end
end
