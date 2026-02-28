defmodule Anu.Config do
  @moduledoc """
  Runtime configuration resolution for Anu.

  All other modules read configuration through this module instead of calling
  `Application.get_env/3` directly.

  ## Configuration keys

      config :anu,
        adapter: Anu.Adapters.Meta,
        access_token: "your_token",
        phone_number_id: "your_phone_number_id",
        verify_token: "your_verify_token",
        app_secret: "your_app_secret",
        api_version: "v21.0"

  ## Finch pool

  By default, Anu starts its own Finch instance named `Anu.Finch`. You can
  configure the pool options or bring your own Finch instance:

      # Configure pool options
      config :anu, :finch_pool, size: 50, count: 4

      # Or bring your own Finch instance
      config :anu, finch: MyApp.Finch

  """

  @doc """
  Returns the configured adapter module.

  Defaults to `Anu.Adapters.Meta`.

  ## Examples

      iex> Application.put_env(:anu, :adapter, Anu.Adapters.Local)
      iex> Anu.Config.adapter()
      Anu.Adapters.Local

  """
  @spec adapter() :: module()
  def adapter do
    Application.get_env(:anu, :adapter, Anu.Adapters.Meta)
  end

  @doc """
  Returns the WhatsApp Cloud API access token.

  Raises if not configured.
  """
  @spec access_token() :: String.t()
  def access_token do
    Application.fetch_env!(:anu, :access_token)
  end

  @doc """
  Returns the WhatsApp phone number ID.

  Raises if not configured.
  """
  @spec phone_number_id() :: String.t()
  def phone_number_id do
    Application.fetch_env!(:anu, :phone_number_id)
  end

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

  @doc """
  Returns the Meta API version.

  Defaults to `"v21.0"`.
  """
  @spec api_version() :: String.t()
  def api_version do
    Application.get_env(:anu, :api_version, "v21.0")
  end

  @doc """
  Returns the Finch instance name to use for HTTP requests.

  If the user configured `:finch`, that value is returned.
  Otherwise, returns `Anu.Finch` (the instance managed by Anu's supervisor).

  ## Examples

      iex> Anu.Config.finch_name()
      Anu.Finch

  """
  @spec finch_name() :: Finch.name()
  def finch_name do
    Application.get_env(:anu, :finch, Anu.Finch)
  end

  @doc """
  Returns the Finch pool options for the managed Finch instance.

  Defaults to `[size: 10, count: 1]`.
  """
  @spec finch_pool_opts() :: keyword()
  def finch_pool_opts do
    Application.get_env(:anu, :finch_pool, size: 10, count: 1)
  end

  @doc """
  Returns `true` if the user provided their own Finch instance.
  """
  @spec custom_finch?() :: boolean()
  def custom_finch? do
    Application.get_env(:anu, :finch) != nil
  end
end
