defmodule Anu.Event.Message do
  @moduledoc """
  Represents an inbound WhatsApp message received via webhook.

  ## Fields

    * `:id` - the message ID (wamid)
    * `:from` - sender's phone number
    * `:timestamp` - Unix timestamp as a string
    * `:type` - message type (e.g. `"text"`, `"image"`, `"button"`)
    * `:text` - text body (for text messages)
    * `:image` - image metadata map
    * `:video` - video metadata map
    * `:document` - document metadata map
    * `:audio` - audio metadata map
    * `:sticker` - sticker metadata map
    * `:location` - location data map
    * `:contacts` - contacts list
    * `:button_reply` - button reply payload (for interactive button responses)
    * `:list_reply` - list reply payload (for interactive list responses)
    * `:raw` - the raw message map from Meta's webhook payload

  """

  @type t :: %__MODULE__{
          id: String.t(),
          from: String.t(),
          timestamp: String.t(),
          type: String.t(),
          text: String.t() | nil,
          image: map() | nil,
          video: map() | nil,
          document: map() | nil,
          audio: map() | nil,
          sticker: map() | nil,
          location: map() | nil,
          contacts: [map()] | nil,
          button_reply: map() | nil,
          list_reply: map() | nil,
          raw: map()
        }

  defstruct [
    :id,
    :from,
    :timestamp,
    :type,
    :text,
    :image,
    :video,
    :document,
    :audio,
    :sticker,
    :location,
    :contacts,
    :button_reply,
    :list_reply,
    :raw
  ]
end
