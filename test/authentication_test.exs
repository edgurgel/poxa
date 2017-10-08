defmodule Poxa.AuthenticationTest do
  use ExUnit.Case
  import :meck
  import Poxa.Authentication

  setup do
    new Application
    new Signaturex
    on_exit fn -> unload() end
    :ok
  end

  test "check with a non-empty body and correct md5" do
    expect(Application, :fetch_env, [{[:poxa, :app_key], {:ok, :app_key}}, {[:poxa, :app_secret], {:ok, :secret}}])
    qs = %{"body_md5" => "841a2d689ad86bd1611447453c22c6fc"}
    expect(Signaturex, :validate, [{[:app_key, :secret, 'get', '/url', qs, 600], :ok}])

    assert check('get', '/url', 'body', qs)

    assert validate Signaturex
    assert validate Application
  end

  test "check with a non-empty body and incorrect md5" do
    expect(Application, :fetch_env, [{[:poxa, :app_key], {:ok, :app_key}}, {[:poxa, :app_secret], {:ok, :secret}}])
    qs = %{"body_md5" => "md5?"}
    expect(Signaturex, :validate, [{[:app_key, :secret, 'get', '/url', qs, 600], :ok}])

    refute check('get', '/url', 'body', qs)

    assert validate Signaturex
    assert validate Application
  end

  test "check with an empty body" do
    expect(Application, :fetch_env, [{[:poxa, :app_key], {:ok, :app_key}}, {[:poxa, :app_secret], {:ok, :secret}}])
    qs = %{}
    expect(Signaturex, :validate, [{[:app_key, :secret, "get", "/url", qs, 600], :ok}])

    assert check("get", "/url", "", qs)

    assert validate Signaturex
    assert validate Application
  end

  test "a valid auth_key" do
    expect(Application, :fetch_env, 2, {:ok, :auth_key})
    assert check_key(:auth_key)
    assert validate Application
  end

  test "an invalid auth_key" do
    expect(Application, :fetch_env, 2, {:ok, :auth_key})
    refute check_key(:invalid_auth_key)
    assert validate Application
  end
end
