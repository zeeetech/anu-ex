defmodule Anu.Event.Status do
  @moduledoc """
  Represents a message status update received via webhook.

  ## Fields

    * `:id` - the message ID (wamid)
    * `:status` - one of `:sent`, `:delivered`, `:read`, or `:failed`
    * `:timestamp` - Unix timestamp as a string
    * `:recipient_id` - the recipient's phone number
    * `:phone_number_id` - the receiving phone number ID (from payload metadata)
    * `:display_phone_number` - the receiving display phone number (from payload metadata)
    * `:raw` - the raw status map from Meta's webhook payload

  """

  @type t :: %__MODULE__{
          id: String.t(),
          status: :sent | :delivered | :read | :failed,
          timestamp: String.t(),
          recipient_id: String.t(),
          phone_number_id: String.t() | nil,
          display_phone_number: String.t() | nil,
          raw: map()
        }

  defstruct [
    :id,
    :status,
    :timestamp,
    :recipient_id,
    :phone_number_id,
    :display_phone_number,
    :raw
  ]
end
