defmodule Poxa.Authentication do
  require Logger
  alias Poxa.CryptoHelper

  @type error_reason :: {:error, binary}

  @doc """
  Returns :ok if every step on authentication is :ok
  More info at: http://pusher.com/docs/rest_api#authentication
  """
  @spec check(binary, binary, binary, [{binary, binary}]) :: :ok | {:badauth, binary}
  def check(method, path, body, qs_vals) do
    try do
      qs_vals = Enum.into(qs_vals, %{})
      #If any of these values are not avaiable -> MatchError
      body_md5 = qs_vals["body_md5"]
      {:ok, app_key} = Application.fetch_env(:poxa, :app_key)
      {:ok, secret} = Application.fetch_env(:poxa, :app_secret)

      :ok = check_body(body, body_md5)

      Signaturex.validate!(app_key, secret, method, path, qs_vals, 600)
      :ok
    rescue
      _error in [MatchError, Signaturex.AuthenticationError] ->
        {:badauth, "Error during authentication"}
    end
  end

  @doc """
  Returns :ok if the auth_key is identical to app_key and
  :error, reason tuple otherwise
  """
  @spec check_key(binary) :: :ok | error_reason
  def check_key(auth_key) do
    {:ok, app_key} = Application.fetch_env(:poxa, :app_key)
    if auth_key == app_key, do: :ok,
    else: {:error, "app_key and auth_key dont match."}
  end

  @doc """
  Returns :ok if the body md5 matches and :error, reason tuple otherwise
  """
  @spec check_body(binary, binary) :: :ok | error_reason
  def check_body("", nil), do: :ok
  def check_body(body, body_md5) do
    md5 = CryptoHelper.md5_to_string(body)
    if md5 == body_md5, do: :ok,
    else: {:error, "body_md5 does not match"}
  end
end
