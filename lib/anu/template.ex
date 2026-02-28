defmodule Anu.Template do
  @moduledoc """
  Helpers for building template message components.

  Template messages require pre-approved templates registered in the WhatsApp
  Business Manager. These helpers build the component parameters that fill in
  the template placeholders.

  ## Examples

      Anu.Message.new("+5511999999999")
      |> Anu.Message.template("order_update", "en_US", [
        Anu.Template.body_param("John"),
        Anu.Template.body_param("#12345")
      ])

  """

  @type param :: map()

  @doc """
  Creates a text parameter for the template body.

  ## Examples

      iex> Anu.Template.body_param("John")
      %{type: "text", text: "John"}

  """
  @spec body_param(String.t()) :: param()
  def body_param(value) when is_binary(value) do
    %{type: "text", text: value}
  end

  @doc """
  Creates an image parameter for the template header.

  ## Examples

      iex> Anu.Template.header_image("https://example.com/img.png")
      %{type: "image", image: %{link: "https://example.com/img.png"}}

  """
  @spec header_image(String.t()) :: param()
  def header_image(url) when is_binary(url) do
    %{type: "image", image: %{link: url}}
  end

  @doc """
  Creates a document parameter for the template header.

  ## Examples

      iex> Anu.Template.header_document("https://example.com/doc.pdf", "invoice.pdf")
      %{type: "document", document: %{link: "https://example.com/doc.pdf", filename: "invoice.pdf"}}

  """
  @spec header_document(String.t(), String.t()) :: param()
  def header_document(url, filename) when is_binary(url) and is_binary(filename) do
    %{type: "document", document: %{link: url, filename: filename}}
  end

  @doc """
  Creates a button parameter for a template button.

  ## Types

    * `"url"` - URL suffix appended to the button URL
    * `"quick_reply"` - payload sent back when user taps the button

  ## Examples

      iex> Anu.Template.button_param("url", "/track/12345")
      %{type: "url", url: "/track/12345"}

      iex> Anu.Template.button_param("quick_reply", "confirm_yes")
      %{type: "quick_reply", payload: "confirm_yes"}

  """
  @spec button_param(String.t(), String.t()) :: param()
  def button_param("url", value) when is_binary(value) do
    %{type: "url", url: value}
  end

  def button_param("quick_reply", value) when is_binary(value) do
    %{type: "quick_reply", payload: value}
  end
end
