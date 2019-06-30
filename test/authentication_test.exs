defmodule Poxa.AuthenticationTest do
  use ExUnit.Case, async: true
  use Mimic
  import Poxa.Authentication

  setup do
    stub(Signaturex)
    :ok
  end

  test "check with a non-empty body and correct md5" do
    qs = %{"body_md5" => "841a2d689ad86bd1611447453c22c6fc"}
    expect(Signaturex, :validate, fn "app_key", "secret", "get", "/url", ^qs, 600 -> :ok end)

    assert check("get", "/url", "body", qs)
  end

  test "check with a non-empty body and incorrect md5" do
    qs = %{"body_md5" => "md5?"}

    refute check("get", "/url", "body", qs)
  end

  test "check with an empty body" do
    qs = %{}
    expect(Signaturex, :validate, fn "app_key", "secret", "get", "/url", ^qs, 600 -> :ok end)

    assert check("get", "/url", "", qs)
  end

  test "a valid auth_key" do
    assert check_key("app_key")
  end

  test "an invalid auth_key" do
    refute check_key(:invalid_auth_key)
  end
end
