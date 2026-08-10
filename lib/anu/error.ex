defmodule Anu.Error do
  @moduledoc """
  Represents an error returned by the WhatsApp Cloud API or an internal failure.

  ## Fields

    * `:code` - error code from Meta API (integer), an anu_cloud code
      (string, e.g. `"quota_exceeded"`), or an internal atom
    * `:message` - human-readable error message
    * `:details` - additional error details (map or nil)
    * `:raw` - the raw response body, if available

  ## Examples

      iex> %Anu.Error{code: 131_047, message: "Re-engagement message"}
      %Anu.Error{code: 131_047, message: "Re-engagement message", details: nil, raw: nil}

  """

  @type t :: %__MODULE__{
          code: integer() | String.t() | atom(),
          message: String.t(),
          details: map() | nil,
          raw: map() | nil
        }

  defstruct [:code, :message, :details, :raw]

  @doc """
  Creates an `Anu.Error` from a Meta API error response body.

  ## Examples

      iex> Anu.Error.from_response(%{"error" => %{"code" => 100, "message" => "Invalid parameter"}})
      %Anu.Error{code: 100, message: "Invalid parameter", details: nil, raw: %{"error" => %{"code" => 100, "message" => "Invalid parameter"}}}

  """
  @spec from_response(map()) :: t()
  def from_response(%{"error" => error} = raw) do
    %__MODULE__{
      code: error["code"],
      message: error["message"],
      details: error["details"] || error["error_data"],
      raw: raw
    }
  end

  def from_response(raw) when is_map(raw) do
    %__MODULE__{
      code: :unknown,
      message: "Unexpected error response",
      raw: raw
    }
  end
end
