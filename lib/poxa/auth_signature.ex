defmodule Poxa.AuthSignature do
  require Logger
  alias Poxa.CryptoHelper

  @doc """
  Validate auth signature as described at: http://pusher.com/docs/auth_signatures .
  Returns :ok or :error
  """
  @spec validate(binary, binary) :: :ok | :error
  def validate(to_sign, auth) do
    case String.split(auth, ":", parts: 2) do
      [app_key, remote_signed_data] ->
        case Poxa.Authentication.check_key(app_key) do
          :ok ->
            signed_data = sign_data(to_sign)
            equals?(signed_data, remote_signed_data)
          _ -> :error
        end
      _ -> :error
    end
  end

  defp sign_data(data) do
    {:ok, app_secret} = :application.get_env(:poxa, :app_secret)
    CryptoHelper.hmac256_to_string(app_secret, data)
  end

  defp equals?(signed_data, signed_data), do: :ok
  defp equals?(_, _) do
    Logger.info "Authentication failed"
    :error
  end
end
