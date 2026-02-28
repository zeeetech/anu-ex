defmodule Anu.Section do
  @moduledoc """
  Represents a section in a list message.

  Each section has a title and a list of `Anu.Row` items.

  ## Examples

      iex> rows = [Anu.Row.new("s", "Small"), Anu.Row.new("m", "Medium")]
      iex> Anu.Section.new("Sizes", rows)
      %Anu.Section{title: "Sizes", rows: [%Anu.Row{id: "s", title: "Small", description: nil}, %Anu.Row{id: "m", title: "Medium", description: nil}]}

  """

  @type t :: %__MODULE__{
          title: String.t(),
          rows: [Anu.Row.t()]
        }

  defstruct [:title, :rows]

  @doc """
  Creates a new section with the given `title` and list of rows.

  ## Examples

      iex> Anu.Section.new("Pick one", [Anu.Row.new("a", "A")])
      %Anu.Section{title: "Pick one", rows: [%Anu.Row{id: "a", title: "A", description: nil}]}

  """
  @spec new(String.t(), [Anu.Row.t()]) :: t()
  def new(title, rows) when is_binary(title) and is_list(rows) do
    %__MODULE__{title: title, rows: rows}
  end
end
