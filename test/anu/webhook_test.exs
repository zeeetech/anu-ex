defmodule Anu.WebhookTest do
  use ExUnit.Case

  alias Anu.Fixtures
  alias Anu.Webhook.Parser
  alias Anu.Webhook.Signature

  describe "Signature.verify/3" do
    test "returns :ok for a valid signature" do
      body = ~S({"entry":[]})
      secret = "test_secret"
      mac = :hmac |> :crypto.mac(:sha256, secret, body) |> Base.encode16(case: :lower)

      assert :ok = Signature.verify(body, "sha256=" <> mac, secret)
    end

    test "returns error for invalid signature" do
      assert {:error, :invalid_signature} = Signature.verify("body", "sha256=bad", "secret")
    end

    test "returns error for missing sha256 prefix" do
      assert {:error, :invalid_signature} = Signature.verify("body", "nope", "secret")
    end
  end

  describe "Parser.parse/1 — text messages" do
    test "parses a text message" do
      [{:message_received, event}] = Parser.parse(Fixtures.text_message_payload())

      assert event.id == "wamid.HBgNNTUxMTk5OTk5OTk5OQ=="
      assert event.from == "5511888888888"
      assert event.type == "text"
      assert event.text == "Hello!"
    end

    test "populates phone number fields from metadata" do
      [{:message_received, event}] = Parser.parse(Fixtures.text_message_payload())

      assert event.phone_number_id == "PHONE_NUMBER_ID"
      assert event.display_phone_number == "5511999999999"
    end

    test "leaves phone number fields nil when metadata is absent" do
      [{:message_received, event}] = Parser.parse(Fixtures.image_message_payload())

      assert event.phone_number_id == nil
      assert event.display_phone_number == nil
    end
  end

  describe "Parser.parse/1 — status updates" do
    test "parses a delivered status" do
      [{:message_status, event}] = Parser.parse(Fixtures.status_update_payload("delivered"))

      assert event.id == "wamid.HBgNNTUxMTk5OTk5OTk5OQ=="
      assert event.status == :delivered
      assert event.recipient_id == "5511999999999"
    end

    test "populates phone number fields from metadata" do
      [{:message_status, event}] = Parser.parse(Fixtures.status_update_payload())

      assert event.phone_number_id == "PHONE_NUMBER_ID"
      assert event.display_phone_number == "5511999999999"
    end

    test "parses all status types" do
      for {status_str, expected} <- [
            {"sent", :sent},
            {"delivered", :delivered},
            {"read", :read},
            {"failed", :failed}
          ] do
        [{:message_status, event}] = Parser.parse(Fixtures.status_update_payload(status_str))
        assert event.status == expected
      end
    end
  end

  describe "Parser.parse/1 — interactive messages" do
    test "parses a button reply" do
      [{:message_received, event}] = Parser.parse(Fixtures.button_reply_payload())

      assert event.type == "interactive"
      assert event.button_reply == %{"id" => "btn_yes", "title" => "Yes"}
    end
  end

  describe "Parser.parse/1 — media messages" do
    test "parses an image message" do
      [{:message_received, event}] = Parser.parse(Fixtures.image_message_payload())

      assert event.type == "image"
      assert event.image["mime_type"] == "image/jpeg"
      assert event.image["id"] == "MEDIA_ID"
    end
  end

  describe "Parser.parse/1 — edge cases" do
    test "returns empty list for empty payload" do
      assert [] = Parser.parse(%{})
    end

    test "returns empty list for nil" do
      assert [] = Parser.parse(nil)
    end
  end
end
