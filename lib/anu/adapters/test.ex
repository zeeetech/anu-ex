defmodule Anu.Adapters.Test do
  @moduledoc """
  Test adapter that sends messages to the current process mailbox.

  Useful for asserting that messages were sent in tests. Use with
  `Anu.TestAssertions` for convenient assertion macros.

  ## Configuration

      # In config/test.exs or test_helper.exs
      config :anu, adapter: Anu.Adapters.Test

  ## Usage

      test "sends a greeting" do
        Anu.Message.new("+5511999999999")
        |> Anu.Message.text("Hello!")
        |> Anu.deliver()

        assert_received {:anu_message, %Anu.Message{to: "+5511999999999", body: "Hello!"}}
      end

  """

  @behaviour Anu.Adapter

  alias Anu.Message
  alias Anu.Response

  @impl true
  def deliver(%Message{} = message, _finch_name) do
    send(self(), {:anu_message, message})
    {:ok, %Response{id: "test_#{System.unique_integer([:positive])}", status: "accepted"}}
  end
end
