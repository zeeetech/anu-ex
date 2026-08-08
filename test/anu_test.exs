defmodule AnuTest do
  use ExUnit.Case

  import Anu.TestAssertions

  setup do
    {:ok, client: Anu.Client.new(adapter: Anu.Adapters.Test, finch: AnuTest.Finch)}
  end

  describe "deliver/2" do
    test "delivers a text message through the client's adapter", %{client: client} do
      {:ok, response} =
        "+5511999999999"
        |> Anu.Message.new()
        |> Anu.Message.text("Hello!")
        |> Anu.deliver(client)

      assert response.status == "accepted"
      assert is_binary(response.id)
      assert_message_sent(to: "+5511999999999", body: "Hello!")
    end

    test "returns ok tuple on success", %{client: client} do
      result =
        "+5511999999999"
        |> Anu.Message.new()
        |> Anu.Message.text("test")
        |> Anu.deliver(client)

      assert {:ok, %Anu.Response{}} = result
    end
  end

  describe "deliver!/2" do
    test "returns the response directly on success", %{client: client} do
      response =
        "+5511999999999"
        |> Anu.Message.new()
        |> Anu.Message.text("Hello!")
        |> Anu.deliver!(client)

      assert %Anu.Response{status: "accepted"} = response
    end
  end
end
