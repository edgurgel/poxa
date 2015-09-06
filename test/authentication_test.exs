defmodule Poxa.AuthenticationTest do
  use ExUnit.Case
  import :meck
  import Poxa.Authentication
  alias Poxa.App

  setup do
    new Application
    new App
    new Signaturex
    on_exit fn -> unload end
    :ok
  end

  test "check with unknown app_key and secret" do
    expect(App, :key_secret, [{[:app_id], {:error, :reason}}])
    qs = %{"body_md5" => "841a2d689ad86bd1611447453c22c6fc"}
    expect(Signaturex, :validate, [{[:app_key, :secret, 'get', '/url', qs, 600], :ok}])

    refute check(:app_id, 'get', '/url', 'body', qs)

    assert validate Signaturex
    assert validate App
  end

  test "check with a non-empty body and correct md5" do
    expect(App, :key_secret, [{[:app_id], {:ok, {:app_key, :secret}}}])
    qs = %{"body_md5" => "841a2d689ad86bd1611447453c22c6fc"}
    expect(Signaturex, :validate, [{[:app_key, :secret, 'get', '/url', qs, 600], :ok}])

    assert check(:app_id, 'get', '/url', 'body', qs)

    assert validate Signaturex
    assert validate App
  end

  test "check with a non-empty body and incorrect md5" do
    expect(App, :key_secret, [{[:app_id], {:ok, {:app_key, :secret}}}])
    qs = %{"body_md5" => "md5?"}
    expect(Signaturex, :validate, [{[:app_key, :secret, 'get', '/url', qs, 600], :ok}])

    refute check(:app_id, 'get', '/url', 'body', qs)

    assert validate Signaturex
    assert validate App
  end

  test "check with an empty body" do
    expect(App, :key_secret, [{[:app_id], {:ok, {:app_key, :secret}}}])
    qs = %{}
    expect(Signaturex, :validate, [{[:app_key, :secret, "get", "/url", qs, 600], :ok}])

    assert check(:app_id, "get", "/url", "", qs)

    assert validate Signaturex
    assert validate App
  end
end
