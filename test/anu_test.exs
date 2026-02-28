defmodule AnuTest do
  use ExUnit.Case

  import Anu.TestAssertions

  describe "deliver/1" do
    test "delivers a text message through the test adapter" do
      {:ok, response} =
        "+5511999999999"
        |> Anu.Message.new()
        |> Anu.Message.text("Hello!")
        |> Anu.deliver()

      assert response.status == "accepted"
      assert is_binary(response.id)
      assert_message_sent(to: "+5511999999999", body: "Hello!")
    end

    test "returns ok tuple on success" do
      result =
        "+5511999999999"
        |> Anu.Message.new()
        |> Anu.Message.text("test")
        |> Anu.deliver()

      assert {:ok, %Anu.Response{}} = result
    end
  end

  describe "deliver!/1" do
    test "returns the response directly on success" do
      response =
        "+5511999999999"
        |> Anu.Message.new()
        |> Anu.Message.text("Hello!")
        |> Anu.deliver!()

      assert %Anu.Response{status: "accepted"} = response
    end
  end
end
