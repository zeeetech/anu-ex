defmodule Anu.Message do
  @moduledoc """
  A composable message builder for the WhatsApp Business API.

  `Anu.Message` is a plain struct that accumulates state as you pipe through
  builder functions. The struct is only serialized to the Meta API format when
  `Anu.deliver/1` is called.

  ## Examples

      # Simple text message
      Anu.Message.new("+5511999999999")
      |> Anu.Message.text("Hello!")
      |> Anu.deliver()

      # Interactive message with buttons
      Anu.Message.new("+5511999999999")
      |> Anu.Message.text("Pick a color")
      |> Anu.Message.buttons([{"Red", "red"}, {"Blue", "blue"}])
      |> Anu.deliver()

      # List message with sections
      Anu.Message.new("+5511999999999")
      |> Anu.Message.text("Our menu")
      |> Anu.Message.button_text("View menu")
      |> Anu.Message.sections([
        Anu.Section.new("Drinks", [
          Anu.Row.new("coffee", "Coffee"),
          Anu.Row.new("tea", "Tea")
        ])
      ])
      |> Anu.deliver()

  """

  @type t :: %__MODULE__{
          to: String.t() | nil,
          type: atom() | nil,
          body: String.t() | nil,
          header: map() | nil,
          footer: String.t() | nil,
          buttons: [{String.t(), String.t() | atom()}] | nil,
          sections: [Anu.Section.t()] | nil,
          button_text: String.t() | nil,
          template: map() | nil,
          location: map() | nil,
          media: map() | nil,
          reaction: map() | nil,
          context: map() | nil
        }

  defstruct [
    :to,
    :type,
    :body,
    :header,
    :footer,
    :buttons,
    :sections,
    :button_text,
    :template,
    :location,
    :media,
    :reaction,
    :context
  ]

  @doc """
  Creates a new message addressed to the given phone number.

  ## Examples

      iex> Anu.Message.new("+5511999999999")
      %Anu.Message{to: "+5511999999999"}

  """
  @spec new(String.t()) :: t()
  def new(to) when is_binary(to) do
    %__MODULE__{to: to}
  end

  @doc """
  Sets the text body of the message.

  ## Examples

      iex> Anu.Message.new("+5511999999999") |> Anu.Message.text("Hello!")
      %Anu.Message{to: "+5511999999999", body: "Hello!"}

  """
  @spec text(t(), String.t()) :: t()
  def text(%__MODULE__{} = message, body) when is_binary(body) do
    %{message | body: body}
  end

  @doc """
  Alias for `text/2`. Useful when building interactive messages where \"body\"
  is the natural term.
  """
  @spec body(t(), String.t()) :: t()
  def body(%__MODULE__{} = message, text) when is_binary(text) do
    text(message, text)
  end

  @doc """
  Sets a text header on the message.

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.header_text("Welcome")
      %Anu.Message{to: "+55", header: %{type: "text", text: "Welcome"}}

  """
  @spec header_text(t(), String.t()) :: t()
  def header_text(%__MODULE__{} = message, text) when is_binary(text) do
    %{message | header: %{type: "text", text: text}}
  end

  @doc """
  Sets an image header on the message.

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.header_image("https://img.com/a.png")
      %Anu.Message{to: "+55", header: %{type: "image", image: %{link: "https://img.com/a.png"}}}

  """
  @spec header_image(t(), String.t()) :: t()
  def header_image(%__MODULE__{} = message, url) when is_binary(url) do
    %{message | header: %{type: "image", image: %{link: url}}}
  end

  @doc """
  Sets a video header on the message.

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.header_video("https://vid.com/v.mp4")
      %Anu.Message{to: "+55", header: %{type: "video", video: %{link: "https://vid.com/v.mp4"}}}

  """
  @spec header_video(t(), String.t()) :: t()
  def header_video(%__MODULE__{} = message, url) when is_binary(url) do
    %{message | header: %{type: "video", video: %{link: url}}}
  end

  @doc """
  Sets a document header on the message.

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.header_document("https://d.com/f.pdf", "file.pdf")
      %Anu.Message{to: "+55", header: %{type: "document", document: %{link: "https://d.com/f.pdf", filename: "file.pdf"}}}

  """
  @spec header_document(t(), String.t(), String.t()) :: t()
  def header_document(%__MODULE__{} = message, url, filename) when is_binary(url) and is_binary(filename) do
    %{message | header: %{type: "document", document: %{link: url, filename: filename}}}
  end

  @doc """
  Sets the footer text on the message.

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.footer("Powered by Anu")
      %Anu.Message{to: "+55", footer: "Powered by Anu"}

  """
  @spec footer(t(), String.t()) :: t()
  def footer(%__MODULE__{} = message, text) when is_binary(text) do
    %{message | footer: text}
  end

  @doc """
  Sets quick reply buttons on the message.

  Each button is a `{title, payload}` tuple. Maximum 3 buttons.

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.buttons([{"Yes", "yes"}, {"No", "no"}])
      %Anu.Message{to: "+55", buttons: [{"Yes", "yes"}, {"No", "no"}]}

      iex> Anu.Message.new("+55") |> Anu.Message.buttons([{"Track", :track}, {"Cancel", :cancel}])
      %Anu.Message{to: "+55", buttons: [{"Track", :track}, {"Cancel", :cancel}]}

  """
  @spec buttons(t(), [{String.t(), String.t() | atom()}]) :: t()
  def buttons(%__MODULE__{} = message, buttons) when is_list(buttons) do
    %{message | buttons: buttons}
  end

  @doc """
  Sets the CTA button text for list messages.

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.button_text("View options")
      %Anu.Message{to: "+55", button_text: "View options"}

  """
  @spec button_text(t(), String.t()) :: t()
  def button_text(%__MODULE__{} = message, text) when is_binary(text) do
    %{message | button_text: text}
  end

  @doc """
  Sets the list sections on the message.

  ## Examples

      iex> sections = [Anu.Section.new("S", [Anu.Row.new("a", "A")])]
      iex> Anu.Message.new("+55") |> Anu.Message.sections(sections)
      %Anu.Message{to: "+55", sections: [%Anu.Section{title: "S", rows: [%Anu.Row{id: "a", title: "A", description: nil}]}]}

  """
  @spec sections(t(), [Anu.Section.t()]) :: t()
  def sections(%__MODULE__{} = message, sections) when is_list(sections) do
    %{message | sections: sections}
  end

  @doc """
  Sets a location on the message.

  ## Options

    * `:name` - location name
    * `:address` - location address

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.location(-23.5505, -46.6333, name: "Sao Paulo")
      %Anu.Message{to: "+55", location: %{latitude: -23.5505, longitude: -46.6333, name: "Sao Paulo", address: nil}}

  """
  @spec location(t(), number(), number(), keyword()) :: t()
  def location(%__MODULE__{} = message, latitude, longitude, opts \\ []) do
    %{
      message
      | location: %{
          latitude: latitude,
          longitude: longitude,
          name: Keyword.get(opts, :name),
          address: Keyword.get(opts, :address)
        }
    }
  end

  @doc """
  Sets the message as a standalone image.

  ## Options

    * `:caption` - image caption

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.image("https://img.com/a.png", caption: "Look!")
      %Anu.Message{to: "+55", media: %{type: "image", url: "https://img.com/a.png", caption: "Look!", filename: nil}}

  """
  @spec image(t(), String.t(), keyword()) :: t()
  def image(%__MODULE__{} = message, url, opts \\ []) when is_binary(url) do
    %{message | media: %{type: "image", url: url, caption: Keyword.get(opts, :caption), filename: nil}}
  end

  @doc """
  Sets the message as a standalone video.

  ## Options

    * `:caption` - video caption

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.video("https://vid.com/v.mp4")
      %Anu.Message{to: "+55", media: %{type: "video", url: "https://vid.com/v.mp4", caption: nil, filename: nil}}

  """
  @spec video(t(), String.t(), keyword()) :: t()
  def video(%__MODULE__{} = message, url, opts \\ []) when is_binary(url) do
    %{message | media: %{type: "video", url: url, caption: Keyword.get(opts, :caption), filename: nil}}
  end

  @doc """
  Sets the message as a standalone document.

  ## Options

    * `:caption` - document caption

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.document("https://d.com/f.pdf", "file.pdf")
      %Anu.Message{to: "+55", media: %{type: "document", url: "https://d.com/f.pdf", caption: nil, filename: "file.pdf"}}

  """
  @spec document(t(), String.t(), String.t(), keyword()) :: t()
  def document(%__MODULE__{} = message, url, filename, opts \\ []) when is_binary(url) and is_binary(filename) do
    %{message | media: %{type: "document", url: url, caption: Keyword.get(opts, :caption), filename: filename}}
  end

  @doc """
  Sets the message as an audio message.

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.audio("https://a.com/audio.ogg")
      %Anu.Message{to: "+55", media: %{type: "audio", url: "https://a.com/audio.ogg", caption: nil, filename: nil}}

  """
  @spec audio(t(), String.t()) :: t()
  def audio(%__MODULE__{} = message, url) when is_binary(url) do
    %{message | media: %{type: "audio", url: url, caption: nil, filename: nil}}
  end

  @doc """
  Sets the message as a sticker.

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.sticker("https://s.com/sticker.webp")
      %Anu.Message{to: "+55", media: %{type: "sticker", url: "https://s.com/sticker.webp", caption: nil, filename: nil}}

  """
  @spec sticker(t(), String.t()) :: t()
  def sticker(%__MODULE__{} = message, url) when is_binary(url) do
    %{message | media: %{type: "sticker", url: url, caption: nil, filename: nil}}
  end

  @doc """
  Sets the message as a reaction to another message.

  ## Options

    * `:message_id` (required) - the ID of the message to react to

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.react("👍", message_id: "wamid.123")
      %Anu.Message{to: "+55", reaction: %{emoji: "👍", message_id: "wamid.123"}}

  """
  @spec react(t(), String.t(), keyword()) :: t()
  def react(%__MODULE__{} = message, emoji, opts) when is_binary(emoji) do
    %{message | reaction: %{emoji: emoji, message_id: Keyword.fetch!(opts, :message_id)}}
  end

  @doc """
  Sets the message as a template message.

  `components` is a list of component maps built with `Anu.Template` helpers.

  ## Examples

      Anu.Message.new("+55")
      |> Anu.Message.template("hello_world", "en_US", [
        Anu.Template.body_param("John")
      ])

  """
  @spec template(t(), String.t(), String.t(), [map()]) :: t()
  def template(%__MODULE__{} = message, name, language, components \\ []) when is_binary(name) and is_binary(language) do
    %{message | template: %{name: name, language: language, components: components}}
  end

  @doc """
  Sets this message as a reply to another message.

  ## Examples

      iex> Anu.Message.new("+55") |> Anu.Message.reply_to("wamid.123")
      %Anu.Message{to: "+55", context: %{message_id: "wamid.123"}}

  """
  @spec reply_to(t(), String.t()) :: t()
  def reply_to(%__MODULE__{} = message, message_id) when is_binary(message_id) do
    %{message | context: %{message_id: message_id}}
  end
end
