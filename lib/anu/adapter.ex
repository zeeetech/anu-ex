defmodule Anu.Adapter do
  @moduledoc """
  Behaviour for message delivery adapters.

  Anu ships with three adapters:

    * `Anu.Adapters.Meta` - production adapter that sends messages via the Meta Cloud API
    * `Anu.Adapters.Local` - development adapter that logs messages to the console
    * `Anu.Adapters.Test` - test adapter that sends messages to the current process

  ## Implementing a custom adapter

  Implement the `c:deliver/2` callback:

      defmodule MyApp.CustomAdapter do
        @behaviour Anu.Adapter

        @impl true
        def deliver(message, finch_name) do
          # Your delivery logic here
          {:ok, %Anu.Response{id: "custom_123"}}
        end
      end

  Then configure it:

      config :anu, adapter: MyApp.CustomAdapter

  """

  @callback deliver(Anu.Message.t(), Finch.name()) ::
              {:ok, Anu.Response.t()} | {:error, Anu.Error.t()}
end
