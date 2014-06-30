defmodule Poxa.AuthenticationTest do
  use ExUnit.Case
  import :meck
  import Poxa.Authentication

  setup do
    new :application, [:unstick]
    on_exit fn -> unload end
    :ok
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
