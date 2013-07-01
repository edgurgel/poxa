defmodule Poxa.Authentication do
  require Lager
  alias Poxa.CryptoHelper

  @type error_reason :: {:error, binary}

  @doc """
  Returns :ok if every step on authentication is :ok
  More info at: http://pusher.com/docs/rest_api#authentication
  """
  @spec check(binary, binary, binary, [{binary, binary}]) :: :ok | {:badauth, binary}
  def check(method, path, body, qs_vals) do
    try do
      #If any of these values are not avaiable -> MatchError
      auth_key = ListDict.get(qs_vals, "auth_key")
      auth_timestamp = ListDict.get(qs_vals, "auth_timestamp")
      auth_version = ListDict.get(qs_vals, "auth_version")
      body_md5 = ListDict.get(qs_vals, "body_md5")
      auth_signature = ListDict.get(qs_vals, "auth_signature")

      :ok = check_key(auth_key)
      :ok = check_timestamp(auth_timestamp)
      :ok = check_version(auth_version)
      :ok = check_body(body, body_md5)
      :ok = check_signature(method, path, auth_key, auth_timestamp,
                           auth_version, body_md5, auth_signature)
    rescue
      MatchError ->
        Lager.info("Error during authentication")
        {:badauth, "Error during authentication"}
    end
  end

  @doc """
  Returns :ok if the auth_key is identical to app_key and
  :error, reason tuple otherwise
  """
  @spec check_key(binary) :: :ok | error_reason
  def check_key(auth_key) do
    {:ok, app_key} = :application.get_env(:poxa, :app_key)
    if auth_key == app_key, do: :ok,
    else: {:error, "app_key and auth_key dont match."}
  end

  @doc """
  Returns :ok if the timestamp is not bigger than 600s and
  :error, reason tuple otherwise
  """
  @spec check_timestamp(binary) :: :ok | error_reason
  def check_timestamp(auth_timestamp) do
    int_auth_timestamp = list_to_integer(binary_to_list(auth_timestamp))
    {mega,sec,_micro} = :os.timestamp()
    timestamp = mega * 1000000 + sec
    case timestamp - int_auth_timestamp do
      diff when diff < 600000 -> :ok
      _ -> {:error, "Old event, timestamp bigger than 600 s"}
    end
  end

  @doc """
  Returns :ok if the version is 1.0 and :error, reason tuple otherwise
  """
  @spec check_version(binary) :: :ok | error_reason
  def check_version(auth_version) do
    if auth_version == "1.0", do: :ok,
    else: {:error, "auth_version is not 1.0"}
  end

  @doc """
  Returns :ok if the body md5 matches and :error, reason tuple otherwise
  """
  @spec check_body(binary, binary) :: :ok | error_reason
  def check_body("", nil), do: :ok
  def check_body(body, body_md5) do
    md5 = CryptoHelper.md5_to_binary(body)
    if md5 == body_md5, do: :ok,
    else: {:error, "body_md5 does not match"}
  end

  @doc """
  This function uses `method`, `path`, `auth_key`, `auth_timetamp`, `auth_version` and `body_md5` to
  check if the signature is correct applying on this order:
      http_verb + path + auth_key + auth_timestamp + auth_version + body_md5
  More info at: https://github.com/mloughran/signature
  """
  @spec check_signature(binary, binary, binary, binary, binary, binary, binary) :: :ok | error_reason
  def check_signature(method, path, auth_key, auth_timestamp,
                      auth_version, body_md5, auth_signature) do
   to_sign = method <> "\n" <> path <>
             "\nauth_key=" <> auth_key <>
             "&auth_timestamp=" <> auth_timestamp <>
             "&auth_version=" <> auth_version
   to_sign = if body_md5 do
     to_sign <> "&body_md5=" <> body_md5
   else
    to_sign
   end
   {:ok, app_secret} = :application.get_env(:poxa, :app_secret)
   signed_data = CryptoHelper.hmac256_to_binary(app_secret, to_sign)
   if signed_data == auth_signature, do: :ok,
   else: {:error, "auth_signature does not match"}
  end
end
