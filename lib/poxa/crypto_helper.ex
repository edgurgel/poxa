defmodule Poxa.CryptoHelper do
  @spec hmac256_to_binary(binary, binary) :: binary
  def hmac256_to_binary(app_secret, to_sign) do
    :hmac.hmac256(app_secret, to_sign)
    |> :hmac.hexlify
    |> :string.to_lower
    |> list_to_binary
  end

  @spec md5_to_binary(binary) :: binary
  def md5_to_binary(data) do
    data
    |> :crypto.md5
    |> :hmac.hexlify
    |> :string.to_lower
    |> list_to_binary
  end

end
