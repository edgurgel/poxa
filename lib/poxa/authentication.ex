defmodule Poxa.Authentication do
  @moduledoc """
  A module that hold authentication validation using Signaturex
  """

  @doc """
  Returns true if authentication process is validated correctly, false otherwise
  More info at: http://pusher.com/docs/rest_api#authentication
  """
  @spec check(binary, binary, binary, [{binary, binary}]) :: boolean
  def check(method, path, body, qs_vals) do
    qs_vals = Enum.into(qs_vals, %{})
    body_md5 = qs_vals["body_md5"]
    {:ok, app_key} = Application.fetch_env(:poxa, :app_key)
    {:ok, secret} = Application.fetch_env(:poxa, :app_secret)

    valid_body?(body, body_md5) and
      Signaturex.validate(app_key, secret, method, path, qs_vals, 600)
  end

  @doc """
  Returns true if the `app_key` is the same as `auth_key`, false otherwise
  """
  @spec check_key(binary) :: boolean
  def check_key(auth_key) do
    {:ok, app_key} = Application.fetch_env(:poxa, :app_key)
    auth_key == app_key
  end

  defp valid_body?("", nil), do: true

  defp valid_body?(body, body_md5) do
    body_md5 == Poxa.CryptoHelper.md5_to_string(body)
  end
end
