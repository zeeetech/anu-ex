defmodule Anu do
  @moduledoc """
  Composable Elixir SDK for the WhatsApp Business API.

  Anu provides a pipe-first API for building and sending WhatsApp messages.

  ## Quick start

  Delivery always goes through an explicit `%Anu.Client{}` holding the
  credentials for one WhatsApp phone number, plus the name of a Finch
  instance started in your own supervision tree:

      client =
        Anu.Client.new(
          finch: MyApp.Finch,
          access_token: "your_whatsapp_token",
          phone_number_id: "your_phone_number_id"
        )

      Anu.Message.new("+5511999999999")
      |> Anu.Message.text("Hello from Anu!")
      |> Anu.deliver(client)

  ## Multiple numbers / WABAs

  Build one client per phone number (or per WABA, when you hold several
  access tokens) and deliver through the matching one:

      support = Anu.Client.new(finch: MyApp.Finch, access_token: "EAAG...", phone_number_id: "111")
      sales   = Anu.Client.new(finch: MyApp.Finch, access_token: "EAAG...", phone_number_id: "222")

      Anu.Message.new("+5511999999999")
      |> Anu.Message.text("Hello from support!")
      |> Anu.deliver(support)

  See `Anu.Client` for all client options and `Anu.Webhook.Plug` for
  webhook configuration.
  """

  @doc """
  Delivers a message through the client's adapter.

  Returns `{:ok, %Anu.Response{}}` on success or `{:error, %Anu.Error{}}` on failure.

  ## Examples

      {:ok, response} =
        Anu.Message.new("+5511999999999")
        |> Anu.Message.text("Hello!")
        |> Anu.deliver(client)

      response.id
      #=> "wamid.HBgN..."

  """
  @spec deliver(Anu.Message.t(), Anu.Client.t()) :: {:ok, Anu.Response.t()} | {:error, Anu.Error.t()}
  def deliver(%Anu.Message{} = message, %Anu.Client{} = client) do
    client.adapter.deliver(message, client)
  end

  @doc """
  Delivers a message, unwrapping the result.

  Returns the `%Anu.Response{}` directly on success. On failure, raises an
  `ArgumentError` with the error details. Useful in scripts and IEx sessions.

  ## Examples

      response =
        Anu.Message.new("+5511999999999")
        |> Anu.Message.text("Hello!")
        |> Anu.deliver!(client)

  """
  @spec deliver!(Anu.Message.t(), Anu.Client.t()) :: Anu.Response.t()
  def deliver!(%Anu.Message{} = message, %Anu.Client{} = client) do
    case deliver(message, client) do
      {:ok, response} ->
        response

      {:error, %Anu.Error{code: code, message: error_message}} ->
        raise ArgumentError, "Anu delivery failed (#{code}): #{error_message}"
    end
  end
end
