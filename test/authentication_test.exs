Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.AuthenticationTest do
  use ExUnit.Case
  import :meck
  import Poxa.Authentication

  setup do
    new :application, [:unstick]
    new :hmac
  end

  teardown do
    unload :application
    unload :hmac
  end

  test "a valid auth_key" do
    expect(:application, :get_env, 2, {:ok, :auth_key})
    assert check_key(:auth_key) == :ok
    assert validate :application
  end

  test "an invalid auth_key" do
    expect(:application, :get_env, 2, {:ok, :auth_key})
    {return, _} = check_key(:invalid_auth_key)
    assert return == :error
    assert validate :application
  end

  test "a valid timestamp" do
    {mega,sec,_micro} = :os.timestamp
    timestamp = (mega * 1000000 + sec)
                |> integer_to_list
                |> list_to_binary
    assert check_timestamp(timestamp) == :ok
  end

  test "an invalid timestamp" do
    {mega,sec,_micro} = :os.timestamp
    timestamp = (mega * 1000000 + sec) - 600001
                |> integer_to_list
                |> list_to_binary
    {return, _} = check_timestamp(timestamp)
    assert return == :error
  end

  test "a valid auth version" do
    assert check_version("1.0") == :ok
  end

  test "an invalid auth version" do
    {return, _} = check_version("2.5")
    assert return == :error
  end

  test "a valid body" do
    body = 'md5'
    md5 = "md5"
    # Impossible to mock crypto module
    expect(:hmac, :hexlify, 1, 'md5')
    assert check_body(body, md5) == :ok
    assert validate :hmac
  end

  test "an invalid body" do
    body = 'wrong-md5'
    md5 = "md5"
    # Impossible to mock crypto module
    expect(:hmac, :hexlify, 1, 'WRONGMD5')
    {return, _} = check_body(body, md5)
    assert return == :error
    assert validate :hmac
  end

  test "an empty  body" do
    assert check_body("", nil) == :ok
  end

  test "a valid signature" do
    expect(:application, :get_env, 2, {:ok, :app_secret})
    expected = "method\npath\nk1=v1&k2=v2"
    expect(:hmac, :hmac256, [{[:app_secret, expected], "auth_signature"}])
    expect(:hmac, :hexlify, 1, 'auth_signature')
    assert check_signature("method", "path", [{"k1", "v1"}, {"k2", "v2"}], "auth_signature") == :ok
    assert validate :hmac
    assert validate :application
  end

  test "an invalid signature" do
    expect(:application, :get_env, 2, {:ok, :app_secret})
    expect(:hmac, :hmac256, 2, "auth_signature")
    expect(:hmac, :hexlify, 1, 'invalid_auth_signature')
    {return, _} = check_signature("method", "path", [], "auth_signature")
    assert return == :error
    assert validate :hmac
    assert validate :application
  end
end
