defmodule Poxa.AuthSignatureTest do
  use ExUnit.Case
  alias Poxa.Authentication
  import :meck
  import Poxa.AuthSignature

  setup do
    new Authentication
    on_exit fn -> unload end
    :ok
  end

  test "a valid signature" do
    :application.set_env(:poxa, :app_secret, "secret")
    app_key = "app_key"
    signature = Poxa.CryptoHelper.hmac256_to_string("secret", "SocketId:private-channel")
    auth = <<app_key :: binary, ":", signature :: binary>>
    expect(Authentication, :check_key, 1, :ok)

    assert validate("SocketId:private-channel", auth) == :ok

    assert validate Authentication
  end

  test "an invalid key" do
    expect(Authentication, :check_key, 1, :error)

    assert validate("SocketId:private-channel", "Auth") == :error

    assert validate Authentication
  end

  test "an invalid signature" do
    :application.set_env(:poxa, :app_secret, "secret")
    expect(Authentication, :check_key, 1, :ok)

    assert validate("SocketId:private-channel", "Wrong:Auth") == :error

    assert validate Authentication
  end
end
