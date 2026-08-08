defmodule Anu.Cloud.ClientTest do
  use ExUnit.Case, async: true

  alias Anu.Cloud.Client

  test "returns :cloud_not_configured when no api key is set" do
    client = Anu.Client.new(finch: AnuCloudClientTest.Finch)

    assert {:error, :cloud_not_configured} = Client.post(client, "/v1/ai/classify", %{})
  end

  test "returns :cloud_not_configured for empty api key" do
    client = Anu.Client.new(finch: AnuCloudClientTest.Finch, cloud_api_key: "")

    assert {:error, :cloud_not_configured} = Client.post(client, "/v1/ai/classify", %{})
  end
end
