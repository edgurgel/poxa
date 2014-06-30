defmodule Poxa.AuthSignatureTest do
  use ExUnit.Case
  alias Poxa.Authentication
  import :meck
  import Poxa.AuthSignature

  setup do
    new Authentication
    new :application, [:unstick]
    on_exit fn -> unload end
    :ok
  end

  test "a valid signature" do
    expect(:application, :get_env, 2, {:ok, "secret"})
    app_key = "app_key"
    signature = Poxa.CryptoHelper.hmac256_to_string("secret", "SocketId:private-channel")
    auth = <<app_key :: binary, ":", signature :: binary>>
    expect(Authentication, :check_key, 1, :ok)
    assert validate("SocketId:private-channel", auth) == :ok
    assert validate :application
    assert validate Authentication
  end

  test "an invalid key" do
    expect(Authentication, :check_key, 1, :error)
    assert validate("SocketId:private-channel", "Auth") == :error
    assert validate :application
    assert validate Authentication
  end

  test "an invalid signature" do
    expect(:application, :get_env, 2, {:ok, "secret"})
    expect(Authentication, :check_key, 1, :ok)
    assert validate("SocketId:private-channel", "Wrong:Auth") == :error
    assert validate :application
    assert validate Authentication
  end
end
