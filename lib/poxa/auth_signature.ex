defmodule Poxa.AuthSignature do
  @moduledoc """
  This module encapsulates the signature validation described at:
  http://pusher.com/docs/auth_signatures
  """

  @doc """
  Validate auth signature as described at: http://pusher.com/docs/auth_signatures .
  Returns true or false
  """
  @spec valid?(binary, binary, binary) :: boolean
  def valid?(app_id, to_sign, auth) do
    case Poxa.App.key_secret(app_id) do
      {:ok, {app_key, app_secret}} ->
        case String.split(auth, ":", parts: 2) do
          [^app_key, remote_signed_data] ->
            signed_data = Poxa.CryptoHelper.hmac256_to_string(app_secret, to_sign)
            signed_data == remote_signed_data
          _ -> false
        end
      {:error, _} -> false
    end
  end
end
