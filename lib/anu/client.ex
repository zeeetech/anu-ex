defmodule Anu.Client do
  @moduledoc """
  An explicit client holding the credentials and settings used to deliver
  messages and call anu_cloud.

  Anu never reads application env for delivery and never starts its own
  Finch instance: you bring a Finch name (started in your own supervision
  tree) and the credentials for each WhatsApp phone number / WABA.

  Build one client per phone number / WABA to run multiple numbers or
  multiple access tokens in the same BEAM node:

      # In your application supervision tree:
      #   {Finch, name: MyApp.Finch}

      support = Anu.Client.new(finch: MyApp.Finch, access_token: "EAAG...", phone_number_id: "111")
      sales   = Anu.Client.new(finch: MyApp.Finch, access_token: "EAAG...", phone_number_id: "222")

      Anu.Message.new("+5511...")
      |> Anu.Message.text("hi")
      |> Anu.deliver(support)

  Credentials (`:access_token`, `:phone_number_id`, `:cloud_api_key`) may be
  `nil` until use; adapters raise at delivery time when they are missing.
  """

  @type t :: %__MODULE__{
          adapter: module(),
          access_token: String.t() | nil,
          phone_number_id: String.t() | nil,
          api_version: String.t(),
          finch: Finch.name(),
          cloud_url: String.t(),
          cloud_api_key: String.t() | nil
        }

  @enforce_keys [:finch]
  defstruct adapter: Anu.Adapters.Meta,
            access_token: nil,
            phone_number_id: nil,
            api_version: "v21.0",
            finch: nil,
            cloud_url: "https://api.anu.zeetech.io",
            cloud_api_key: nil

  @doc """
  Builds a client from the given attributes.

  `:finch` is required. Library defaults are used for anything not given.
  Accepts a keyword list or a map. Unknown keys raise `KeyError` via
  `struct!/2`.

  ## Examples

      iex> Anu.Client.new(finch: MyApp.Finch, access_token: "EAAG...", phone_number_id: "111")
      %Anu.Client{finch: MyApp.Finch, access_token: "EAAG...", phone_number_id: "111"}

  """
  @spec new(keyword() | map()) :: t()
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    struct!(__MODULE__, attrs)
  end
end
