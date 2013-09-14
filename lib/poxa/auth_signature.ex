defmodule Poxa.AuthSignature do
  require Lager
  alias Poxa.CryptoHelper

  @doc """
  Validate auth signature as described at: http://pusher.com/docs/auth_signatures .
  Returns :ok or :error
  """
  @spec validate(binary, binary) :: :ok | :error
  def validate(to_sign, auth) do
    case String.split(auth, ":", global: false) do
      [app_key, remote_signed_data] ->
        case Poxa.Authentication.check_key(app_key) do
          :ok ->
            {:ok, app_secret} = :application.get_env(:poxa, :app_secret)
            signed_data = CryptoHelper.hmac256_to_string(app_secret, to_sign)
            if signed_data == remote_signed_data do
              :ok
            else
              Lager.info("Authentication failed.")
              :error
            end
          { :error, _reason } -> :error
        end
      _ -> :error
    end
  end
end
