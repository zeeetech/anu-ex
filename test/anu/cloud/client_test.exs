defmodule Anu.Cloud.ClientTest do
  # Not async — mutates application env.
  use ExUnit.Case, async: false

  alias Anu.Cloud.Client

  setup do
    prev = Application.get_env(:anu, :cloud_api_key)
    on_exit(fn -> Application.put_env(:anu, :cloud_api_key, prev) end)
    :ok
  end

  test "returns :cloud_not_configured when no api key is set" do
    Application.delete_env(:anu, :cloud_api_key)

    assert {:error, :cloud_not_configured} = Client.post("/v1/ai/classify", %{})
  end

  test "returns :cloud_not_configured for empty api key" do
    Application.put_env(:anu, :cloud_api_key, "")

    assert {:error, :cloud_not_configured} = Client.post("/v1/ai/classify", %{})
  end
end
