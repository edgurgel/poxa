defmodule Poxa.Authentication do
  @moduledoc """
  A module that hold authentication validation using Signaturex
  """

  @doc """
  Returns :ok if every step on authentication is :ok
  More info at: http://pusher.com/docs/rest_api#authentication
  """
  @spec check(binary, binary, binary, [{binary, binary}]) :: boolean
  def check(method, path, body, qs_vals) do
    qs_vals = Enum.into(qs_vals, %{})
    #If any of these values are not avaiable -> MatchError
    body_md5 = qs_vals["body_md5"]
    {:ok, app_key} = Application.fetch_env(:poxa, :app_key)
    {:ok, secret} = Application.fetch_env(:poxa, :app_secret)

    valid_body?(body, body_md5) and Signaturex.validate(app_key, secret, method, path, qs_vals, 600)
  end

  @doc """
  Returns :ok if the auth_key is identical to app_key and
  :error, reason tuple otherwise
  """
  @spec check_key(binary) :: :ok | {:error, binary}
  def check_key(auth_key) do
    {:ok, app_key} = Application.fetch_env(:poxa, :app_key)
    if auth_key == app_key, do: :ok,
    else: {:error, "app_key and auth_key dont match."}
  end

  defp valid_body?("", nil), do: true
  defp valid_body?(body, body_md5) do
    body_md5 == Poxa.CryptoHelper.md5_to_string(body)
  end
end
