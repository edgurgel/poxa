defmodule Poxa.AuthSignature do
  @moduledoc """
  This module encapsulates the signature validation described at:
  http://pusher.com/docs/auth_signatures
  """

  require Logger
  alias Poxa.CryptoHelper

  @doc """
  Validate auth signature as described at: http://pusher.com/docs/auth_signatures .
  Returns true or false
  """
  @spec valid?(binary, binary) :: boolean
  def valid?(to_sign, auth) do
    case String.split(auth, ":", parts: 2) do
      [app_key, remote_signed_data] ->
        signed_data = sign_data(to_sign)
        Poxa.Authentication.check_key(app_key) and signed_data == remote_signed_data

      _ ->
        false
    end
  end

  defp sign_data(data) do
    {:ok, app_secret} = :application.get_env(:poxa, :app_secret)
    CryptoHelper.hmac256_to_string(app_secret, data)
  end
end
