defmodule Anu.Row do
  @moduledoc """
  Represents a row item inside a list message section.

  ## Fields

    * `:id` - unique identifier for the row (sent back on selection)
    * `:title` - display title (max 24 characters)
    * `:description` - optional description text (max 72 characters)

  ## Examples

      iex> Anu.Row.new("opt_1", "Option 1")
      %Anu.Row{id: "opt_1", title: "Option 1", description: nil}

      iex> Anu.Row.new("opt_2", "Option 2", description: "More details")
      %Anu.Row{id: "opt_2", title: "Option 2", description: "More details"}

  """

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          description: String.t() | nil
        }

  defstruct [:id, :title, :description]

  @doc """
  Creates a new row with the given `id` and `title`.

  ## Options

    * `:description` - optional description text

  ## Examples

      iex> Anu.Row.new("size_s", "Small")
      %Anu.Row{id: "size_s", title: "Small", description: nil}

  """
  @spec new(String.t(), String.t(), keyword()) :: t()
  def new(id, title, opts \\ []) when is_binary(id) and is_binary(title) do
    %__MODULE__{
      id: id,
      title: title,
      description: Keyword.get(opts, :description)
    }
  end
end
