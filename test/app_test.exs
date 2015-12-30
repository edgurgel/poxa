defmodule Poxa.AppTest do
  use ExUnit.Case
  import Poxa.App

  setup_all do
    Application.put_env(:poxa, :apps, [{"app_id2", "app_key2", "app_secret2"}])
    :ok = Poxa.App.reload
    :ok
  end

  test "search for existing id using the key" do
    assert id("app_key") == {:ok, "app_id"}
    assert id("app_key2") == {:ok, "app_id2"}
  end

  test "search for existing key using the id" do
    assert key("app_id") == {:ok, "app_key"}
    assert key("app_id2") == {:ok, "app_key2"}
  end

  test "search for existing key and secret using the id" do
    assert key_secret("app_id") == {:ok, {"app_key", "secret"}}
    assert key_secret("app_id2") == {:ok, {"app_key2", "app_secret2"}}
  end

  test "search for inexisting id using the key" do
    assert id("no_app_key") == {:error, {:key_not_found, "no_app_key"}}
  end

  test "search for inexisting key using the id" do
    assert key("no_app_id") == {:error, {:id_not_found, "no_app_id"}}
  end

  test "search for inexisting key and secret using the id" do
    assert key_secret("no_app_id") == {:error, {:id_not_found, "no_app_id"}}
  end
end
