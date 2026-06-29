defmodule Anu.AI do
  @moduledoc """
  Cloud-powered AI helpers backed by [anu_cloud](https://anu.zeetech.io).

  These primitives let you classify, extract, draft, and summarize WhatsApp
  conversation text without managing your own LLM provider. Pair them with
  `Anu.Message` to build conversational flows in a few lines.

  ## Configuration

      config :anu,
        cloud_api_key: System.fetch_env!("ANU_API_KEY")

  Optional:

      config :anu, :cloud_url, "https://api.anu.zeetech.io"  # default

  ## Example

      with {:ok, %{"intent" => "support"}} <-
             Anu.AI.classify(text, intents: ["support", "sales", "spam"]),
           {:ok, %{"reply" => reply}} <-
             Anu.AI.reply(text, tone: "warm") do
        from
        |> Anu.Message.new()
        |> Anu.Message.text(reply)
        |> Anu.deliver()
      end

  All functions return `{:ok, decoded_map}` or `{:error, %Anu.Error{} | :cloud_not_configured}`.
  Response keys are strings (decoded JSON).
  """

  alias Anu.Error

  @type result :: {:ok, map()} | {:error, Error.t() | :cloud_not_configured}

  @doc """
  Classifies `text` against a list of `intents`. Returns `{intent, confidence}`.

  ## Options

    * `:intents` (required) - list of candidate intent strings.

  ## Examples

      Anu.AI.classify("I need to reset my password",
        intents: ["support", "sales", "spam"]
      )
      #=> {:ok, %{"intent" => "support", "confidence" => 0.93}}
  """
  @spec classify(String.t(), keyword()) :: result()
  def classify(text, opts) when is_binary(text) and is_list(opts) do
    intents = Keyword.fetch!(opts, :intents)
    client().post("/v1/ai/classify", %{text: text, intents: intents})
  end

  @doc """
  Extracts structured data from `text` matching the given JSON `schema`.

  ## Options

    * `:schema` (required) - a map describing the fields to extract.

  ## Examples

      Anu.AI.extract("My name is Ana and my order is #123",
        schema: %{name: "string", order_id: "string"}
      )
      #=> {:ok, %{"data" => %{"name" => "Ana", "order_id" => "123"}}}
  """
  @spec extract(String.t(), keyword()) :: result()
  def extract(text, opts) when is_binary(text) and is_list(opts) do
    schema = Keyword.fetch!(opts, :schema)
    client().post("/v1/ai/extract", %{text: text, schema: schema})
  end

  @doc """
  Drafts a reply to the user `text`.

  ## Options

    * `:context` - extra background to ground the reply (string)
    * `:tone` - e.g. `"warm"`, `"professional"`, `"playful"`

  ## Examples

      Anu.AI.reply("when does my package arrive?", tone: "warm")
      #=> {:ok, %{"reply" => "Hi! Your package is on its way..."}}
  """
  @spec reply(String.t(), keyword()) :: result()
  def reply(text, opts \\ []) when is_binary(text) and is_list(opts) do
    body =
      %{text: text}
      |> maybe_put(:context, opts[:context])
      |> maybe_put(:tone, opts[:tone])

    client().post("/v1/ai/reply", body)
  end

  @doc """
  Summarizes a list of conversation messages into a short summary.

  ## Examples

      Anu.AI.summarize([
        %{role: "user", content: "hi"},
        %{role: "assistant", content: "hello, how can I help?"}
      ])
      #=> {:ok, %{"summary" => "User said hi; we offered help."}}
  """
  @spec summarize([map()]) :: result()
  def summarize(messages) when is_list(messages) do
    client().post("/v1/ai/summarize", %{messages: messages})
  end

  defp client, do: Application.get_env(:anu, :cloud_client, Anu.Cloud.Client)

  defp maybe_put(map, _k, nil), do: map
  defp maybe_put(map, k, v), do: Map.put(map, k, v)
end
