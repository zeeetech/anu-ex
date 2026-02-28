defmodule Anu.Response do
  @moduledoc """
  Represents a successful response from the WhatsApp Cloud API.

  ## Fields

    * `:id` - the message ID returned by Meta (e.g. `"wamid.HBg..."`)
    * `:status` - delivery status string (usually `"accepted"`)
    * `:raw` - the full parsed response body

  ## Examples

      iex> %Anu.Response{id: "wamid.HBgN", status: "accepted"}
      %Anu.Response{id: "wamid.HBgN", status: "accepted", raw: nil}

  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          status: String.t() | nil,
          raw: map() | nil
        }

  defstruct [:id, :status, :raw]

  @doc """
  Creates an `Anu.Response` from a Meta API success response body.

  ## Examples

      iex> body = %{"messages" => [%{"id" => "wamid.123"}]}
      iex> Anu.Response.from_body(body)
      %Anu.Response{id: "wamid.123", status: "accepted", raw: %{"messages" => [%{"id" => "wamid.123"}]}}

  """
  @spec from_body(map()) :: t()
  def from_body(%{"messages" => [%{"id" => id} | _]} = body) do
    %__MODULE__{id: id, status: "accepted", raw: body}
  end

  def from_body(body) when is_map(body) do
    %__MODULE__{raw: body}
  end
end
