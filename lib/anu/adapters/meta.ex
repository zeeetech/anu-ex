defmodule Anu.Adapters.Meta do
  @moduledoc """
  Production adapter that sends messages via the Meta WhatsApp Cloud API.

  Uses Finch for HTTP and the native `JSON` module for encoding.
  All configuration is read through `Anu.Config`.
  """

  @behaviour Anu.Adapter

  alias Anu.Config
  alias Anu.Error
  alias Anu.Message
  alias Anu.Response

  @impl true
  def deliver(%Message{} = message, finch_name) do
    url = build_url()
    body = message |> serialize() |> JSON.encode!()

    :post
    |> Finch.build(url, headers(), body)
    |> Finch.request(finch_name)
    |> handle_response()
  end

  defp build_url do
    "https://graph.facebook.com/#{Config.api_version()}/#{Config.phone_number_id()}/messages"
  end

  defp headers do
    [
      {"authorization", "Bearer #{Config.access_token()}"},
      {"content-type", "application/json"}
    ]
  end

  defp handle_response({:ok, %Finch.Response{status: status, body: body}}) when status in 200..299 do
    {:ok, body |> JSON.decode!() |> Response.from_body()}
  end

  defp handle_response({:ok, %Finch.Response{body: body}}) do
    {:error, body |> JSON.decode!() |> Error.from_response()}
  end

  defp handle_response({:error, reason}) do
    {:error, %Error{code: :transport, message: "HTTP request failed: #{inspect(reason)}"}}
  end

  # --- Serialization ---

  @doc false
  @spec serialize(Message.t()) :: map()
  def serialize(%Message{} = message) do
    payload = %{messaging_product: "whatsapp", to: message.to}

    payload
    |> put_context(message)
    |> put_message_body(message)
  end

  defp put_context(payload, %Message{context: %{message_id: id}}) do
    Map.put(payload, :context, %{message_id: id})
  end

  defp put_context(payload, _message), do: payload

  defp put_message_body(payload, %Message{reaction: %{emoji: _, message_id: _} = reaction}) do
    payload
    |> Map.put(:type, "reaction")
    |> Map.put(:reaction, reaction)
  end

  defp put_message_body(payload, %Message{template: %{name: _, language: _} = template}) do
    payload
    |> Map.put(:type, "template")
    |> Map.put(:template, serialize_template(template))
  end

  defp put_message_body(payload, %Message{location: %{latitude: _, longitude: _} = location}) do
    loc = location |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()

    payload
    |> Map.put(:type, "location")
    |> Map.put(:location, loc)
  end

  defp put_message_body(payload, %Message{media: %{type: type} = media}) do
    media_payload =
      %{link: media.url}
      |> maybe_put(:caption, media.caption)
      |> maybe_put(:filename, media.filename)

    payload
    |> Map.put(:type, type)
    |> Map.put(String.to_existing_atom(type), media_payload)
  end

  defp put_message_body(payload, %Message{sections: sections} = message) when is_list(sections) and sections != [] do
    interactive =
      %{
        type: "list",
        body: %{text: message.body},
        action: %{
          button: message.button_text || "Options",
          sections: Enum.map(sections, &serialize_section/1)
        }
      }
      |> maybe_put_header(message.header)
      |> maybe_put_footer(message.footer)

    payload
    |> Map.put(:type, "interactive")
    |> Map.put(:interactive, interactive)
  end

  defp put_message_body(payload, %Message{buttons: buttons} = message) when is_list(buttons) and buttons != [] do
    interactive =
      %{
        type: "button",
        body: %{text: message.body},
        action: %{
          buttons:
            buttons
            |> Enum.with_index()
            |> Enum.map(fn {{title, id}, index} ->
              %{type: "reply", reply: %{id: id || "btn_#{index}", title: title}}
            end)
        }
      }
      |> maybe_put_header(message.header)
      |> maybe_put_footer(message.footer)

    payload
    |> Map.put(:type, "interactive")
    |> Map.put(:interactive, interactive)
  end

  defp put_message_body(payload, %Message{body: body}) when is_binary(body) do
    payload
    |> Map.put(:type, "text")
    |> Map.put(:text, %{body: body})
  end

  defp serialize_template(%{name: name, language: language, components: components}) do
    template = %{
      name: name,
      language: %{code: language}
    }

    case build_template_components(components) do
      [] -> template
      built -> Map.put(template, :components, built)
    end
  end

  defp build_template_components(components) when is_list(components) do
    {header_params, body_params, button_params} = classify_template_params(components)

    []
    |> maybe_add_component("header", header_params)
    |> maybe_add_component("body", body_params)
    |> add_button_components(button_params)
  end

  defp build_template_components(_), do: []

  defp classify_template_params(components) do
    Enum.reduce(components, {[], [], []}, fn
      %{type: "image"} = param, {headers, bodies, buttons} ->
        {[param | headers], bodies, buttons}

      %{type: "document"} = param, {headers, bodies, buttons} ->
        {[param | headers], bodies, buttons}

      %{type: "text"} = param, {headers, bodies, buttons} ->
        {headers, bodies ++ [param], buttons}

      %{type: "url"} = param, {headers, bodies, buttons} ->
        {headers, bodies, buttons ++ [param]}

      %{type: "quick_reply"} = param, {headers, bodies, buttons} ->
        {headers, bodies, buttons ++ [param]}

      _other, acc ->
        acc
    end)
  end

  defp maybe_add_component(components, _type, []), do: components

  defp maybe_add_component(components, type, params) do
    [%{type: type, parameters: params} | components]
  end

  defp add_button_components(components, []), do: components

  defp add_button_components(components, button_params) do
    button_components =
      button_params
      |> Enum.with_index()
      |> Enum.map(fn {param, index} ->
        %{type: "button", sub_type: param.type, index: index, parameters: [serialize_button_param(param)]}
      end)

    components ++ button_components
  end

  defp serialize_button_param(%{type: "url", url: value}) do
    %{type: "text", text: value}
  end

  defp serialize_button_param(%{type: "quick_reply", payload: value}) do
    %{type: "payload", payload: value}
  end

  defp serialize_section(%Anu.Section{title: title, rows: rows}) do
    %{
      title: title,
      rows: Enum.map(rows, &serialize_row/1)
    }
  end

  defp serialize_row(%Anu.Row{id: id, title: title, description: description}) do
    maybe_put(%{id: id, title: title}, :description, description)
  end

  defp maybe_put_header(interactive, nil), do: interactive
  defp maybe_put_header(interactive, header), do: Map.put(interactive, :header, header)

  defp maybe_put_footer(interactive, nil), do: interactive
  defp maybe_put_footer(interactive, footer), do: Map.put(interactive, :footer, %{text: footer})

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
