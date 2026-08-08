defmodule Anu.Adapters.Local do
  @moduledoc """
  Development adapter that logs messages to the console.

  Useful for local development when you don't want to hit the Meta API.

  ## Usage

      client = Anu.Client.new(adapter: Anu.Adapters.Local, finch: MyApp.Finch)

      Anu.Message.new("+5511999999999")
      |> Anu.Message.text("Hello!")
      |> Anu.deliver(client)

  """

  @behaviour Anu.Adapter

  alias Anu.Message
  alias Anu.Response

  require Logger

  @impl true
  def deliver(%Message{} = message, %Anu.Client{}) do
    Logger.info("""
    [Anu.Local] Message to #{message.to}
      type: #{infer_type(message)}
      body: #{message.body || "(none)"}
    """)

    {:ok, %Response{id: "local_#{System.unique_integer([:positive])}", status: "accepted"}}
  end

  defp infer_type(%Message{reaction: %{}}), do: "reaction"
  defp infer_type(%Message{template: %{}}), do: "template"
  defp infer_type(%Message{location: %{}}), do: "location"
  defp infer_type(%Message{media: %{type: type}}), do: type
  defp infer_type(%Message{sections: sections}) when is_list(sections), do: "list"
  defp infer_type(%Message{buttons: buttons}) when is_list(buttons), do: "button"
  defp infer_type(%Message{body: body}) when is_binary(body), do: "text"
  defp infer_type(_), do: "unknown"
end
