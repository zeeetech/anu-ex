defmodule Anu.TestAssertions do
  @moduledoc """
  ExUnit assertion helpers for testing Anu message delivery.

  Requires the test adapter (`Anu.Adapters.Test`) to be configured.

  ## Usage

      defmodule MyApp.NotifierTest do
        use ExUnit.Case
        import Anu.TestAssertions

        test "sends welcome message" do
          Anu.Message.new("+5511999999999")
          |> Anu.Message.text("Welcome!")
          |> Anu.deliver()

          assert_message_sent to: "+5511999999999", body: "Welcome!"
        end

        test "does not send if condition is false" do
          refute_message_sent()
        end
      end

  """

  @doc """
  Asserts that a message was sent via the test adapter.

  Accepts an optional keyword list of fields to match against the
  `%Anu.Message{}` struct.

  ## Examples

      assert_message_sent()
      assert_message_sent(to: "+5511999999999")
      assert_message_sent(to: "+5511999999999", body: "hello")

  """
  defmacro assert_message_sent(fields \\ []) do
    quote do
      assert_received {:anu_message, %Anu.Message{} = message}

      for {field, expected} <- unquote(fields) do
        actual = Map.get(message, field)

        assert actual == expected,
               "Expected message.#{field} to be #{inspect(expected)}, got #{inspect(actual)}"
      end
    end
  end

  @doc """
  Refutes that any message was sent via the test adapter.

  ## Examples

      refute_message_sent()

  """
  defmacro refute_message_sent do
    quote do
      refute_received {:anu_message, _}
    end
  end
end
