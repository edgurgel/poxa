defmodule Poxa.CryptoHelper do
  @spec hmac256_to_string(binary, binary) :: binary
  def hmac256_to_string(app_secret, to_sign) do
    :hmac.hmac256(app_secret, to_sign)
    |> :hmac.hexlify
    |> :string.to_lower
    |> String.from_char_list!
  end

  @spec md5_to_string(binary) :: binary
  def md5_to_string(data) do
    data
    |> :crypto.md5
    |> :hmac.hexlify
    |> :string.to_lower
    |> String.from_char_list!
  end

end
