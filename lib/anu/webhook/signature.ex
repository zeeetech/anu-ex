defmodule Anu.Webhook.Signature do
  @moduledoc """
  HMAC-SHA256 signature verification for Meta webhook payloads.

  Meta signs each webhook POST request with the app secret. This module
  computes the expected signature and compares it using constant-time
  comparison to prevent timing attacks.
  """

  @doc """
  Verifies that the given signature matches the HMAC-SHA256 of the body.

  The `signature` parameter is the value of the `x-hub-signature-256` header,
  which has the format `"sha256=<hex_digest>"`.

  Returns `:ok` if valid, `{:error, :invalid_signature}` otherwise.

  ## Examples

      iex> body = ~S({"entry":[]})
      iex> secret = "test_secret"
      iex> mac = :crypto.mac(:hmac, :sha256, secret, body) |> Base.encode16(case: :lower)
      iex> Anu.Webhook.Signature.verify(body, "sha256=" <> mac, secret)
      :ok

      iex> Anu.Webhook.Signature.verify("body", "sha256=invalid", "secret")
      {:error, :invalid_signature}

  """
  @spec verify(binary(), String.t(), String.t()) :: :ok | {:error, :invalid_signature}
  def verify(body, "sha256=" <> hex_digest, secret) when is_binary(body) and is_binary(secret) do
    expected = :hmac |> :crypto.mac(:sha256, secret, body) |> Base.encode16(case: :lower)

    if Plug.Crypto.secure_compare(expected, hex_digest) do
      :ok
    else
      {:error, :invalid_signature}
    end
  end

  def verify(_body, _signature, _secret) do
    {:error, :invalid_signature}
  end
end
