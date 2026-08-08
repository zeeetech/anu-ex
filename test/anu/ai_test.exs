defmodule Anu.AITest do
  use ExUnit.Case, async: true

  import Mox

  alias Anu.Cloud.ClientMock

  setup :verify_on_exit!

  setup do
    {:ok, client: Anu.Client.new(finch: AnuAITest.Finch)}
  end

  describe "classify/3" do
    test "POSTs to /v1/ai/classify with text + intents", %{client: client} do
      expect(ClientMock, :post, fn ^client, "/v1/ai/classify", body ->
        assert body == %{text: "hi", intents: ["greet", "other"]}
        {:ok, %{"intent" => "greet", "confidence" => 0.99}}
      end)

      assert {:ok, %{"intent" => "greet"}} =
               Anu.AI.classify("hi", [intents: ["greet", "other"]], client)
    end

    test "raises when :intents is missing", %{client: client} do
      assert_raise KeyError, fn -> Anu.AI.classify("hi", [], client) end
    end
  end

  describe "extract/3" do
    test "POSTs to /v1/ai/extract with text + schema", %{client: client} do
      schema = %{name: "string"}

      expect(ClientMock, :post, fn ^client, "/v1/ai/extract", body ->
        assert body == %{text: "I'm Ana", schema: schema}
        {:ok, %{"data" => %{"name" => "Ana"}}}
      end)

      assert {:ok, %{"data" => %{"name" => "Ana"}}} =
               Anu.AI.extract("I'm Ana", [schema: schema], client)
    end
  end

  describe "reply/3" do
    test "omits optional context/tone when not given", %{client: client} do
      expect(ClientMock, :post, fn ^client, "/v1/ai/reply", body ->
        assert body == %{text: "hello"}
        {:ok, %{"reply" => "Hi there!"}}
      end)

      assert {:ok, %{"reply" => "Hi there!"}} = Anu.AI.reply("hello", [], client)
    end

    test "forwards context + tone when set", %{client: client} do
      expect(ClientMock, :post, fn ^client, "/v1/ai/reply", body ->
        assert body.text == "hello"
        assert body.context == "vip customer"
        assert body.tone == "warm"
        {:ok, %{"reply" => "Hi VIP!"}}
      end)

      assert {:ok, _} = Anu.AI.reply("hello", [context: "vip customer", tone: "warm"], client)
    end
  end

  describe "summarize/2" do
    test "POSTs to /v1/ai/summarize with messages", %{client: client} do
      msgs = [%{from: "user", text: "hi"}]

      expect(ClientMock, :post, fn ^client, "/v1/ai/summarize", body ->
        assert body == %{messages: msgs}
        {:ok, %{"summary" => "user said hi"}}
      end)

      assert {:ok, %{"summary" => "user said hi"}} = Anu.AI.summarize(msgs, client)
    end
  end

  describe "error propagation" do
    test "propagates :cloud_not_configured", %{client: client} do
      expect(ClientMock, :post, fn _, _, _ -> {:error, :cloud_not_configured} end)

      assert {:error, :cloud_not_configured} = Anu.AI.reply("hi", [], client)
    end

    test "propagates Anu.Error{}", %{client: client} do
      err = %Anu.Error{code: 401, message: "invalid_api_key"}

      expect(ClientMock, :post, fn _, _, _ -> {:error, err} end)

      assert {:error, ^err} = Anu.AI.classify("x", [intents: ["a"]], client)
    end
  end
end
