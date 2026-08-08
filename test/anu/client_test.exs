defmodule Anu.ClientTest do
  use ExUnit.Case, async: true

  alias Anu.Adapters.Local
  alias Anu.Client

  describe "new/1" do
    test "applies library defaults" do
      client = Client.new(finch: MyApp.Finch)

      assert client.adapter == Anu.Adapters.Meta
      assert client.api_version == "v21.0"
      assert client.finch == MyApp.Finch
      assert client.cloud_url == "https://api.anu.zeetech.io"
      assert client.access_token == nil
      assert client.phone_number_id == nil
      assert client.cloud_api_key == nil
    end

    test "overrides defaults with given attributes" do
      client =
        Client.new(
          finch: MyApp.Finch,
          adapter: Local,
          access_token: "EAAG...",
          phone_number_id: "111",
          api_version: "v22.0",
          cloud_url: "https://staging.example.com",
          cloud_api_key: "anu_sk_test"
        )

      assert client.adapter == Local
      assert client.access_token == "EAAG..."
      assert client.phone_number_id == "111"
      assert client.api_version == "v22.0"
      assert client.cloud_url == "https://staging.example.com"
      assert client.cloud_api_key == "anu_sk_test"
    end

    test "accepts a map of attributes" do
      client = Client.new(%{finch: MyApp.Finch, phone_number_id: "222"})

      assert client.finch == MyApp.Finch
      assert client.phone_number_id == "222"
    end

    test "requires :finch" do
      assert_raise ArgumentError, fn -> Client.new([]) end
    end

    test "raises on unknown keys" do
      assert_raise KeyError, fn -> Client.new(finch: MyApp.Finch, unknown: 1) end
    end
  end
end
