Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.AuthSignatureTest do
  use ExUnit.Case
  alias Poxa.Authentication
  import Poxa.AuthSignature

  setup do
    :meck.new(Authentication)
    :meck.new(:application, [:unstick])
  end

  teardown do
    :meck.unload(Authentication)
    :meck.unload(:application)
  end

  test "a valid signature" do
    :meck.expect(:application, :get_env, 2, {:ok, "secret"})
    app_key = "app_key"
    signature = Poxa.CryptoHelper.hmac256_to_binary("secret", "SocketId:private-channel")
    auth = <<app_key :: binary, ":", signature :: binary>>
    :meck.expect(Authentication, :check_key, 1, :ok)
    assert validate("SocketId:private-channel", auth) == :ok
    assert :meck.validate :application
    assert :meck.validate Authentication
  end

  test "an invalid key" do
    :meck.expect(Authentication, :check_key, 1, :error)
    assert validate("SocketId:private-channel", "Auth") == :error
    assert :meck.validate :application
    assert :meck.validate Authentication
  end

  test "an invalid signature" do
    :meck.expect(:application, :get_env, 2, {:ok, "secret"})
    :meck.expect(Authentication, :check_key, 1, :ok)
    assert validate("SocketId:private-channel", "Wrong:Auth") == :error
    assert :meck.validate :application
    assert :meck.validate Authentication
  end
end
