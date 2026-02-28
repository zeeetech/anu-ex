defmodule Anu.MessageTest do
  use ExUnit.Case

  alias Anu.Message
  alias Anu.Row
  alias Anu.Section

  describe "new/1" do
    test "creates a message with a phone number" do
      message = Message.new("+5511999999999")
      assert message.to == "+5511999999999"
    end
  end

  describe "text/2" do
    test "sets the body" do
      message = "+55" |> Message.new() |> Message.text("hello")
      assert message.body == "hello"
    end
  end

  describe "body/2" do
    test "is an alias for text/2" do
      message = "+55" |> Message.new() |> Message.body("hello")
      assert message.body == "hello"
    end
  end

  describe "header builders" do
    test "header_text/2 sets a text header" do
      message = "+55" |> Message.new() |> Message.header_text("Welcome")
      assert message.header == %{type: "text", text: "Welcome"}
    end

    test "header_image/2 sets an image header" do
      message = "+55" |> Message.new() |> Message.header_image("https://img.com/a.png")
      assert message.header == %{type: "image", image: %{link: "https://img.com/a.png"}}
    end

    test "header_video/2 sets a video header" do
      message = "+55" |> Message.new() |> Message.header_video("https://vid.com/v.mp4")
      assert message.header == %{type: "video", video: %{link: "https://vid.com/v.mp4"}}
    end

    test "header_document/3 sets a document header" do
      message = "+55" |> Message.new() |> Message.header_document("https://d.com/f.pdf", "file.pdf")

      assert message.header == %{
               type: "document",
               document: %{link: "https://d.com/f.pdf", filename: "file.pdf"}
             }
    end
  end

  describe "footer/2" do
    test "sets the footer text" do
      message = "+55" |> Message.new() |> Message.footer("Powered by Anu")
      assert message.footer == "Powered by Anu"
    end
  end

  describe "buttons/2" do
    test "sets quick reply buttons" do
      buttons = [{"Yes", "yes"}, {"No", "no"}]
      message = "+55" |> Message.new() |> Message.buttons(buttons)
      assert message.buttons == buttons
    end
  end

  describe "button_text/2" do
    test "sets the CTA text for list messages" do
      message = "+55" |> Message.new() |> Message.button_text("View options")
      assert message.button_text == "View options"
    end
  end

  describe "sections/2" do
    test "sets list sections" do
      sections = [Section.new("S1", [Row.new("a", "A")])]
      message = "+55" |> Message.new() |> Message.sections(sections)
      assert message.sections == sections
    end
  end

  describe "location/4" do
    test "sets a location" do
      message = "+55" |> Message.new() |> Message.location(-23.55, -46.63, name: "SP")
      assert message.location.latitude == -23.55
      assert message.location.longitude == -46.63
      assert message.location.name == "SP"
    end
  end

  describe "media builders" do
    test "image/3 sets image media" do
      message = "+55" |> Message.new() |> Message.image("https://img.com/a.png", caption: "Look!")
      assert message.media.type == "image"
      assert message.media.url == "https://img.com/a.png"
      assert message.media.caption == "Look!"
    end

    test "video/3 sets video media" do
      message = "+55" |> Message.new() |> Message.video("https://vid.com/v.mp4")
      assert message.media.type == "video"
      assert message.media.url == "https://vid.com/v.mp4"
    end

    test "document/4 sets document media" do
      message = "+55" |> Message.new() |> Message.document("https://d.com/f.pdf", "file.pdf")
      assert message.media.type == "document"
      assert message.media.filename == "file.pdf"
    end

    test "audio/2 sets audio media" do
      message = "+55" |> Message.new() |> Message.audio("https://a.com/audio.ogg")
      assert message.media.type == "audio"
    end

    test "sticker/2 sets sticker media" do
      message = "+55" |> Message.new() |> Message.sticker("https://s.com/sticker.webp")
      assert message.media.type == "sticker"
    end
  end

  describe "react/3" do
    test "sets a reaction" do
      message = "+55" |> Message.new() |> Message.react("👍", message_id: "wamid.123")
      assert message.reaction == %{emoji: "👍", message_id: "wamid.123"}
    end
  end

  describe "template/4" do
    test "sets a template message" do
      message = "+55" |> Message.new() |> Message.template("hello_world", "en_US")
      assert message.template.name == "hello_world"
      assert message.template.language == "en_US"
      assert message.template.components == []
    end
  end

  describe "reply_to/2" do
    test "sets the context message ID" do
      message = "+55" |> Message.new() |> Message.reply_to("wamid.123")
      assert message.context == %{message_id: "wamid.123"}
    end
  end

  describe "pipe composition" do
    test "builds a complete interactive message" do
      message =
        "+5511999999999"
        |> Message.new()
        |> Message.text("Pick a color")
        |> Message.header_text("Color picker")
        |> Message.footer("Reply to choose")
        |> Message.buttons([{"Red", "red"}, {"Blue", "blue"}, {"Green", "green"}])

      assert message.to == "+5511999999999"
      assert message.body == "Pick a color"
      assert message.header == %{type: "text", text: "Color picker"}
      assert message.footer == "Reply to choose"
      assert length(message.buttons) == 3
    end

    test "builds a list message with sections" do
      message =
        "+5511999999999"
        |> Message.new()
        |> Message.text("Our menu")
        |> Message.button_text("View menu")
        |> Message.sections([
          Section.new("Drinks", [
            Row.new("coffee", "Coffee", description: "Hot coffee"),
            Row.new("tea", "Tea")
          ]),
          Section.new("Food", [
            Row.new("sandwich", "Sandwich")
          ])
        ])

      assert message.to == "+5511999999999"
      assert message.body == "Our menu"
      assert message.button_text == "View menu"
      assert length(message.sections) == 2
    end
  end
end
