defmodule Poxa.AuthenticationTest do
  use ExUnit.Case
  import :meck
  import Poxa.Authentication

  setup do
    new Application
    new Signaturex
    on_exit fn -> unload end
    :ok
  end

  test "check with a non-empty body and correct md5" do
    expect(Application, :fetch_env, [{[:poxa, :app_key], {:ok, :app_key}}, {[:poxa, :app_secret], {:ok, :secret}}])
    qs = %{"body_md5" => "841a2d689ad86bd1611447453c22c6fc"}
    expect(Signaturex, :validate!, [{[:app_key, :secret, 'get', '/url', qs, 600], :ok}])

    assert check('get', '/url', 'body', qs) == :ok

    assert validate Signaturex
    assert validate Application
  end

  test "check with a non-empty body and incorrect md5" do
    expect(Application, :fetch_env, [{[:poxa, :app_key], {:ok, :app_key}}, {[:poxa, :app_secret], {:ok, :secret}}])
    qs = %{"body_md5" => "md5?"}
    expect(Signaturex, :validate!, [{[:app_key, :secret, 'get', '/url', qs, 600], :ok}])

    assert check('get', '/url', 'body', qs) == {:badauth, "Error during authentication"}

    assert validate Signaturex
    assert validate Application
  end

  test "check with an empty body" do
    expect(Application, :fetch_env, [{[:poxa, :app_key], {:ok, :app_key}}, {[:poxa, :app_secret], {:ok, :secret}}])
    qs = %{}
    expect(Signaturex, :validate!, [{[:app_key, :secret, "get", "/url", qs, 600], :ok}])

    assert check("get", "/url", "", qs) == :ok

    assert validate Signaturex
    assert validate Application
  end

  test "a valid auth_key" do
    expect(Application, :fetch_env, 2, {:ok, :auth_key})
    assert check_key(:auth_key) == :ok
    assert validate Application
  end

  test "an invalid auth_key" do
    expect(Application, :fetch_env, 2, {:ok, :auth_key})
    {return, _} = check_key(:invalid_auth_key)
    assert return == :error
    assert validate Application
  end

  test "a valid body" do
    body = 'md5'
    md5 = "1bc29b36f623ba82aaf6724fd3b16718"
    # Impossible to mock crypto module
    assert check_body(body, md5) == :ok
  end

  test "an invalid body" do
    body = 'wrong-md5'
    md5 = "md5"
    # Impossible to mock crypto module
    {return, _} = check_body(body, md5)
    assert return == :error
  end

  test "an empty body" do
    assert check_body("", nil) == :ok
  end
end
