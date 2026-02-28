defmodule Anu.Webhook.Parser do
  @moduledoc """
  Parses Meta webhook JSON payloads into event structs.

  Meta's webhook format is deeply nested:

      body.entry[].changes[].value.messages[]
      body.entry[].changes[].value.statuses[]

  This module extracts messages and statuses and converts them into
  `Anu.Event.Message` and `Anu.Event.Status` structs.
  """

  alias Anu.Event

  @type event :: {:message_received, Event.Message.t()} | {:message_status, Event.Status.t()}

  @doc """
  Parses a decoded webhook payload into a list of event tuples.

  Returns a list of `{event_type, event_struct}` tuples.

  ## Examples

      iex> payload = %{"entry" => [%{"changes" => [%{"value" => %{"messages" => [%{"id" => "wamid.1", "from" => "5511999999999", "timestamp" => "1234567890", "type" => "text", "text" => %{"body" => "hi"}}]}}]}]}
      iex> [{:message_received, event}] = Anu.Webhook.Parser.parse(payload)
      iex> event.text
      "hi"

  """
  @spec parse(map()) :: [event()]
  def parse(%{"entry" => entries}) when is_list(entries) do
    entries
    |> Enum.flat_map(fn %{"changes" => changes} -> changes end)
    |> Enum.flat_map(&parse_change/1)
  end

  def parse(_), do: []

  defp parse_change(%{"value" => value}) do
    messages = parse_messages(Map.get(value, "messages", []))
    statuses = parse_statuses(Map.get(value, "statuses", []))
    messages ++ statuses
  end

  defp parse_change(_), do: []

  defp parse_messages(messages) when is_list(messages) do
    Enum.map(messages, fn message ->
      {:message_received, parse_message(message)}
    end)
  end

  defp parse_messages(_), do: []

  defp parse_message(message) do
    %Event.Message{
      id: message["id"],
      from: message["from"],
      timestamp: message["timestamp"],
      type: message["type"],
      text: get_in(message, ["text", "body"]),
      image: message["image"],
      video: message["video"],
      document: message["document"],
      audio: message["audio"],
      sticker: message["sticker"],
      location: message["location"],
      contacts: message["contacts"],
      button_reply: get_in(message, ["interactive", "button_reply"]),
      list_reply: get_in(message, ["interactive", "list_reply"]),
      raw: message
    }
  end

  defp parse_statuses(statuses) when is_list(statuses) do
    Enum.map(statuses, fn status ->
      {:message_status, parse_status(status)}
    end)
  end

  defp parse_statuses(_), do: []

  defp parse_status(status) do
    %Event.Status{
      id: status["id"],
      status: parse_status_value(status["status"]),
      timestamp: status["timestamp"],
      recipient_id: status["recipient_id"],
      raw: status
    }
  end

  defp parse_status_value("sent"), do: :sent
  defp parse_status_value("delivered"), do: :delivered
  defp parse_status_value("read"), do: :read
  defp parse_status_value("failed"), do: :failed
  defp parse_status_value(_), do: :unknown
end
