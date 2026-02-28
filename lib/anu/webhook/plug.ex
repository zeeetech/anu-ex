defmodule Anu.Webhook.Plug do
  @moduledoc """
  A Plug that handles incoming WhatsApp webhook requests.

  This Plug handles two types of requests:

    * **GET** — Meta's webhook verification challenge. Compares the
      `hub.verify_token` query parameter against the configured verify token
      and returns the `hub.challenge` value.

    * **POST** — Incoming webhook events. Verifies the `x-hub-signature-256`
      header, parses the payload, and dispatches events to the configured handler.

  ## Usage

  In a Phoenix router:

      forward "/webhook/whatsapp", Anu.Webhook.Plug, handler: MyApp.WhatsAppHandler

  In a plain Plug router:

      forward "/webhook/whatsapp", to: Anu.Webhook.Plug, init_opts: [handler: MyApp.WhatsAppHandler]

  ## Options

    * `:handler` (required) — a module implementing `Anu.Webhook.Handler`
    * `:secret` — app secret for signature verification; falls back to `Anu.Config.app_secret/0`

  """

  @behaviour Plug

  import Plug.Conn

  alias Anu.Webhook.Parser
  alias Anu.Webhook.Signature

  @impl true
  def init(opts) do
    handler = Keyword.fetch!(opts, :handler)
    %{handler: handler, secret: Keyword.get(opts, :secret)}
  end

  @impl true
  def call(%Plug.Conn{method: "GET"} = conn, _opts) do
    params = fetch_query_params(conn).query_params

    with token when is_binary(token) <- params["hub.verify_token"],
         challenge when is_binary(challenge) <- params["hub.challenge"],
         true <- Plug.Crypto.secure_compare(token, Anu.Config.verify_token()) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, challenge)
    else
      _ ->
        conn |> send_resp(403, "Forbidden") |> halt()
    end
  end

  def call(%Plug.Conn{method: "POST"} = conn, %{handler: handler, secret: secret}) do
    secret = secret || Anu.Config.app_secret()

    with {:ok, body, conn} <- read_body(conn),
         signature when is_binary(signature) <- get_signature(conn),
         :ok <- Signature.verify(body, signature, secret),
         {:ok, payload} <- decode_body(body) do
      events = Parser.parse(payload)
      Enum.each(events, fn {event_type, event} -> handler.handle_event(event_type, event) end)

      conn |> send_resp(200, "OK") |> halt()
    else
      _ ->
        conn |> send_resp(200, "OK") |> halt()
    end
  end

  def call(conn, _opts) do
    conn |> send_resp(405, "Method Not Allowed") |> halt()
  end

  defp get_signature(conn) do
    case get_req_header(conn, "x-hub-signature-256") do
      [signature] -> signature
      _ -> nil
    end
  end

  defp decode_body(body) do
    {:ok, JSON.decode!(body)}
  rescue
    _ -> {:error, :invalid_json}
  end
end
