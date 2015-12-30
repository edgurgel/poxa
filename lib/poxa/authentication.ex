defmodule Poxa.Authentication do
  @moduledoc """
  A module that hold authentication validation using Signaturex
  """

  @doc """
  Returns true if authentication process is validated correctly, false otherwise
  More info at: http://pusher.com/docs/rest_api#authentication
  """
  @spec check(binary, binary, binary, binary, [{binary, binary}]) :: boolean
  def check(app_id, method, path, body, qs_vals) do
    qs_vals = Enum.into(qs_vals, %{})
    body_md5 = qs_vals["body_md5"]
    case Poxa.App.key_secret(app_id) do
      {:ok, {app_key, secret}} ->
        valid_body?(body, body_md5) and Signaturex.validate(app_key, secret, method, path, qs_vals, 600)
      {:error, _} -> false
    end
  end

  defp valid_body?("", nil), do: true
  defp valid_body?(body, body_md5) do
    body_md5 == Poxa.CryptoHelper.md5_to_string(body)
  end
end
