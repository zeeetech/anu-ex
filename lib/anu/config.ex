defmodule Anu.Config do
  @moduledoc """
  Runtime configuration for webhook secrets.

  Delivery and cloud credentials are never read from application env; they
  live on an explicit `%Anu.Client{}` (see `Anu.Client`). This module only
  resolves the webhook secrets used as fallbacks by `Anu.Webhook.Plug` when
  the `:secret` / `:verify_token` plug options are not given.

  ## Configuration keys

      config :anu,
        verify_token: "your_verify_token",
        app_secret: "your_app_secret"

  """

  @doc """
  Returns the webhook verification token.

  Raises if not configured.
  """
  @spec verify_token() :: String.t()
  def verify_token do
    Application.fetch_env!(:anu, :verify_token)
  end

  @doc """
  Returns the WhatsApp app secret for webhook signature verification.

  Raises if not configured.
  """
  @spec app_secret() :: String.t()
  def app_secret do
    Application.fetch_env!(:anu, :app_secret)
  end
end
