defmodule Poxa.AuthSignatureTest do
  use ExUnit.Case, async: true
  alias Poxa.Authentication
  use Mimic
  import Poxa.AuthSignature

  setup do
    stub(Authentication)
    :ok
  end

  test "a valid signature" do
    :application.set_env(:poxa, :app_secret, "secret")
    app_key = "app_key"
    signature = Poxa.CryptoHelper.hmac256_to_string("secret", "SocketId:private-channel")
    auth = <<app_key::binary, ":", signature::binary>>
    expect(Authentication, :check_key, fn _ -> true end)

    assert valid?("SocketId:private-channel", auth)
  end

  test "an invalid key" do
    expect(Authentication, :check_key, fn _ -> false end)

    refute valid?("SocketId:private-channel", "Auth:key")
  end

  test "an invalid signature" do
    :application.set_env(:poxa, :app_secret, "secret")
    expect(Authentication, :check_key, fn _ -> true end)

    refute valid?("SocketId:private-channel", "Wrong:Auth")
  end

  test "invalid " do
    :application.set_env(:poxa, :app_secret, "secret")

    refute valid?("SocketId:private-channel", "asdfasdf")
    refute valid?("SocketId:private-channel", "asdfasdf")
  end
end
