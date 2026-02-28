defmodule Anu.Webhook.Handler do
  @moduledoc """
  Behaviour for handling incoming WhatsApp webhook events.

  Implement this behaviour in your application to receive and process
  webhook events dispatched by `Anu.Webhook.Plug`.

  ## Example

      defmodule MyApp.WhatsAppHandler do
        @behaviour Anu.Webhook.Handler

        @impl true
        def handle_event(:message_received, %Anu.Event.Message{} = event) do
          IO.puts("Message from \#{event.from}: \#{event.text}")
          :ok
        end

        @impl true
        def handle_event(:message_status, %Anu.Event.Status{} = event) do
          IO.puts("Message \#{event.id} is now \#{event.status}")
          :ok
        end
      end

  """

  @type event_type :: :message_received | :message_status

  @callback handle_event(event_type(), Anu.Event.Message.t() | Anu.Event.Status.t()) ::
              :ok | {:error, term()}
end
