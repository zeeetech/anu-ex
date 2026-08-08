defmodule Anu.Adapters.Test do
  @moduledoc """
  Test adapter that sends messages to the current process mailbox.

  Useful for asserting that messages were sent in tests. Use with
  `Anu.TestAssertions` for convenient assertion macros.

  ## Usage

      test "sends a greeting" do
        client = Anu.Client.new(adapter: Anu.Adapters.Test, finch: MyApp.Finch)

        Anu.Message.new("+5511999999999")
        |> Anu.Message.text("Hello!")
        |> Anu.deliver(client)

        assert_received {:anu_message, %Anu.Message{to: "+5511999999999", body: "Hello!"}}
      end

  """

  @behaviour Anu.Adapter

  alias Anu.Message
  alias Anu.Response

  @impl true
  def deliver(%Message{} = message, %Anu.Client{}) do
    send(self(), {:anu_message, message})
    {:ok, %Response{id: "test_#{System.unique_integer([:positive])}", status: "accepted"}}
  end
end
