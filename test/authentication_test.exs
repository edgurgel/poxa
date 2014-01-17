Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.AuthenticationTest do
  use ExUnit.Case
  import :meck
  import Poxa.Authentication

  setup do
    new :application, [:unstick]
  end

  teardown do
    unload :application
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
                |> String.from_char_list!
    assert check_timestamp(timestamp) == :ok
  end

  test "an invalid timestamp" do
    {mega,sec,_micro} = :os.timestamp
    timestamp = (mega * 1000000 + sec) - 600001
                |> integer_to_list
                |> String.from_char_list!
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

  test "an empty  body" do
    assert check_body("", nil) == :ok
  end

  test "a valid signature" do
    expect(:application, :get_env, 2, {:ok, "app_secret"})
    signature = "7d3deaf17d0df9af22263e52cf1899e966136a04456c67938b0d01e147d58c48"
    assert check_signature("method", "path", [{"k1", "v1"}, {"k2", "v2"}], signature) == :ok
    assert validate :application
  end

  test "an invalid signature" do
    expect(:application, :get_env, 2, {:ok, "app_secret"})
    {return, _} = check_signature("method", "path", [], "auth_signature")
    assert return == :error
    assert validate :application
  end
end
