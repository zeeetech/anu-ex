defmodule Anu.Event.Status do
  @moduledoc """
  Represents a message status update received via webhook.

  ## Fields

    * `:id` - the message ID (wamid)
    * `:status` - one of `:sent`, `:delivered`, `:read`, or `:failed`
    * `:timestamp` - Unix timestamp as a string
    * `:recipient_id` - the recipient's phone number
    * `:raw` - the raw status map from Meta's webhook payload

  """

  @type t :: %__MODULE__{
          id: String.t(),
          status: :sent | :delivered | :read | :failed,
          timestamp: String.t(),
          recipient_id: String.t(),
          raw: map()
        }

  defstruct [:id, :status, :timestamp, :recipient_id, :raw]
end
