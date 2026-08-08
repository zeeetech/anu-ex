defmodule Anu.Webhook.PlugTest do
  use ExUnit.Case, async: true

  alias Anu.Webhook.Plug, as: WebhookPlug

  defmodule TestHandler do
    @moduledoc false
    @behaviour Anu.Webhook.Handler

    @impl true
    def handle_event(event_type, event) do
      send(self(), {:webhook_event, event_type, event})
      :ok
    end
  end

  @secret "test_app_secret"

  setup do
    opts = WebhookPlug.init(handler: TestHandler, secret: @secret)
    {:ok, opts: opts}
  end

  describe "GET - verification challenge" do
    test "returns the challenge when verify_token matches", %{opts: opts} do
      conn =
        :get
        |> Plug.Test.conn("/webhook?hub.mode=subscribe&hub.verify_token=test_verify_token&hub.challenge=challenge_123")
        |> WebhookPlug.call(opts)

      assert conn.status == 200
      assert conn.resp_body == "challenge_123"
    end

    test "returns 403 when verify_token does not match", %{opts: opts} do
      conn =
        :get
        |> Plug.Test.conn("/webhook?hub.mode=subscribe&hub.verify_token=wrong&hub.challenge=test")
        |> WebhookPlug.call(opts)

      assert conn.status == 403
    end

    test "uses the :verify_token init opt over the configured token" do
      opts = WebhookPlug.init(handler: TestHandler, secret: @secret, verify_token: "app_two_token")

      conn =
        :get
        |> Plug.Test.conn("/webhook?hub.mode=subscribe&hub.verify_token=app_two_token&hub.challenge=challenge_456")
        |> WebhookPlug.call(opts)

      assert conn.status == 200
      assert conn.resp_body == "challenge_456"
    end

    test "rejects the configured token when a :verify_token opt is given" do
      opts = WebhookPlug.init(handler: TestHandler, secret: @secret, verify_token: "app_two_token")

      conn =
        :get
        |> Plug.Test.conn("/webhook?hub.mode=subscribe&hub.verify_token=test_verify_token&hub.challenge=test")
        |> WebhookPlug.call(opts)

      assert conn.status == 403
    end
  end

  describe "POST - webhook events" do
    test "dispatches parsed events to handler", %{opts: opts} do
      body = JSON.encode!(Anu.Fixtures.text_message_payload())
      signature = sign(body)

      conn =
        :post
        |> Plug.Test.conn("/webhook", body)
        |> Plug.Conn.put_req_header("x-hub-signature-256", signature)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> WebhookPlug.call(opts)

      assert conn.status == 200
      assert_received {:webhook_event, :message_received, %Anu.Event.Message{text: "Hello!"}}
    end

    test "returns 200 even with invalid signature (Meta retries on non-200)", %{opts: opts} do
      body = JSON.encode!(Anu.Fixtures.text_message_payload())

      conn =
        :post
        |> Plug.Test.conn("/webhook", body)
        |> Plug.Conn.put_req_header("x-hub-signature-256", "sha256=invalid")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> WebhookPlug.call(opts)

      assert conn.status == 200
      refute_received {:webhook_event, _, _}
    end
  end

  describe "unsupported methods" do
    test "returns 405 for PUT", %{opts: opts} do
      conn =
        :put
        |> Plug.Test.conn("/webhook")
        |> WebhookPlug.call(opts)

      assert conn.status == 405
    end
  end

  defp sign(body) do
    mac = :hmac |> :crypto.mac(:sha256, @secret, body) |> Base.encode16(case: :lower)
    "sha256=" <> mac
  end
end
