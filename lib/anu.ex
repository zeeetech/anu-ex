defmodule Anu do
  @moduledoc """
  Composable Elixir SDK for the WhatsApp Business API.

  Anu provides a pipe-first API for building and sending WhatsApp messages.

  ## Quick start

      Anu.Message.new("+5511999999999")
      |> Anu.Message.text("Hello from Anu!")
      |> Anu.deliver()

  ## Configuration

      config :anu,
        access_token: "your_whatsapp_token",
        phone_number_id: "your_phone_number_id",
        verify_token: "your_webhook_verify_token",
        app_secret: "your_app_secret"

  See `Anu.Config` for all configuration options.
  """

  alias Anu.Config

  @doc """
  Delivers a message through the configured adapter.

  Returns `{:ok, %Anu.Response{}}` on success or `{:error, %Anu.Error{}}` on failure.

  ## Examples

      {:ok, response} =
        Anu.Message.new("+5511999999999")
        |> Anu.Message.text("Hello!")
        |> Anu.deliver()

      response.id
      #=> "wamid.HBgN..."

  """
  @spec deliver(Anu.Message.t()) :: {:ok, Anu.Response.t()} | {:error, Anu.Error.t()}
  def deliver(%Anu.Message{} = message) do
    adapter = Config.adapter()
    adapter.deliver(message, Config.finch_name())
  end

  @doc """
  Delivers a message, unwrapping the result.

  Returns the `%Anu.Response{}` directly on success. On failure, raises an
  `ArgumentError` with the error details. Useful in scripts and IEx sessions.

  ## Examples

      response =
        Anu.Message.new("+5511999999999")
        |> Anu.Message.text("Hello!")
        |> Anu.deliver!()

  """
  @spec deliver!(Anu.Message.t()) :: Anu.Response.t()
  def deliver!(%Anu.Message{} = message) do
    case deliver(message) do
      {:ok, response} ->
        response

      {:error, %Anu.Error{code: code, message: error_message}} ->
        raise ArgumentError, "Anu delivery failed (#{code}): #{error_message}"
    end
  end
end
