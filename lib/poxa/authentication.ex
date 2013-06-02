defmodule Poxa.Authentication do
  require Lager
  alias Poxa.CryptoHelper

  @doc """
  Returns :ok if every step on authentication is :ok
  More info at: http://pusher.com/docs/rest_api#authentication
  """
  def check(path, body, qs_vals) do
    try do
      #If any of these values are not avaiable -> MatchError
      auth_key = :proplists.get_value("auth_key", qs_vals)
      auth_timestamp = :proplists.get_value("auth_timestamp", qs_vals)
      auth_version = :proplists.get_value("auth_version", qs_vals)
      body_md5 = :proplists.get_value("body_md5", qs_vals)
      auth_signature = :proplists.get_value("auth_signature", qs_vals)

      :ok = check_key(auth_key)
      :ok = check_timestamp(auth_timestamp)
      :ok = check_version(auth_version)
      :ok = check_body(body, body_md5)
      :ok = check_signature(path, auth_key, auth_timestamp,
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
  def check_key(auth_key) do
    {:ok, app_key} = :application.get_env(:poxa, :app_key)
    if auth_key == app_key, do: :ok,
    else: {:error, "app_key and auth_key dont match."}
  end

  @doc """
  Returns :ok if the timestamp is not bigger than 600s and
  :error, reason tuple otherwise
  """
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
  def check_version(auth_version) do
    if auth_version == "1.0", do: :ok,
    else: {:error, "auth_version is not 1.0"}
  end

  @doc """
  Returns :ok if the body md5 matches and :error, reason tuple otherwise
  """
  def check_body(body, body_md5) do
    md5 = CryptoHelper.md5_to_binary(body)
    if md5 == body_md5, do: :ok,
    else: {:error, "body_md5 does not match"}
  end

  @doc """
  This function uses `path`, `auth_key`, `auth_timetamp`, `auth_version` and `body_md5` to
  check if the signature is correct applying on this order:
      http_verb + path + auth_key + auth_timestamp + auth_version + body_md5
  More info at: https://github.com/mloughran/signature
  """
  def check_signature(path, auth_key, auth_timestamp,
                      auth_version, body_md5, auth_signature) do
  #"POST\n/apps/3/events\nauth_key=278d425bdf160c739803&auth_timestamp=1353088179&auth_version=1.0&body_md5=ec365a775a4cd0599faeb73354201b6f"
    to_sign = list_to_binary([ 'POST\n', path,
                               '\nauth_key=', auth_key,
                               '&auth_timestamp=', auth_timestamp,
                               '&auth_version=', auth_version,
                               '&body_md5=', body_md5 ])
   {:ok, app_secret} = :application.get_env(:poxa, :app_secret)
   signed_data = CryptoHelper.hmac256_to_binary(app_secret, to_sign)
   if signed_data == auth_signature, do: :ok,
   else: {:error, "auth_signature does not match"}
  end
end
