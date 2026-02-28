defmodule Anu.Adapters.MetaTest do
  use ExUnit.Case

  alias Anu.Adapters.Meta
  alias Anu.Message
  alias Anu.Row
  alias Anu.Section
  alias Anu.Template

  describe "serialize/1 — text messages" do
    test "serializes a plain text message" do
      payload =
        "+5511999999999"
        |> Message.new()
        |> Message.text("Hello!")
        |> Meta.serialize()

      assert payload == %{
               messaging_product: "whatsapp",
               to: "+5511999999999",
               type: "text",
               text: %{body: "Hello!"}
             }
    end

    test "includes context when replying" do
      payload =
        "+55"
        |> Message.new()
        |> Message.text("reply")
        |> Message.reply_to("wamid.original")
        |> Meta.serialize()

      assert payload.context == %{message_id: "wamid.original"}
    end
  end

  describe "serialize/1 — interactive button messages" do
    test "serializes buttons" do
      payload =
        "+55"
        |> Message.new()
        |> Message.text("Pick one")
        |> Message.buttons([{"Yes", "yes"}, {"No", "no"}])
        |> Meta.serialize()

      assert payload.type == "interactive"
      assert payload.interactive.type == "button"
      assert payload.interactive.body == %{text: "Pick one"}

      buttons = payload.interactive.action.buttons
      assert length(buttons) == 2
      assert Enum.at(buttons, 0).reply.title == "Yes"
      assert Enum.at(buttons, 0).reply.id == "yes"
    end

    test "includes header and footer when set" do
      payload =
        "+55"
        |> Message.new()
        |> Message.text("Pick")
        |> Message.header_text("Title")
        |> Message.footer("Footer")
        |> Message.buttons([{"A", "a"}])
        |> Meta.serialize()

      assert payload.interactive.header == %{type: "text", text: "Title"}
      assert payload.interactive.footer == %{text: "Footer"}
    end
  end

  describe "serialize/1 — list messages" do
    test "serializes sections and rows" do
      payload =
        "+55"
        |> Message.new()
        |> Message.text("Menu")
        |> Message.button_text("Open")
        |> Message.sections([
          Section.new("Drinks", [
            Row.new("coffee", "Coffee", description: "Hot"),
            Row.new("tea", "Tea")
          ])
        ])
        |> Meta.serialize()

      assert payload.type == "interactive"
      assert payload.interactive.type == "list"
      assert payload.interactive.action.button == "Open"

      [section] = payload.interactive.action.sections
      assert section.title == "Drinks"
      assert length(section.rows) == 2

      [coffee, tea] = section.rows
      assert coffee == %{id: "coffee", title: "Coffee", description: "Hot"}
      assert tea == %{id: "tea", title: "Tea"}
    end
  end

  describe "serialize/1 — media messages" do
    test "serializes an image" do
      payload =
        "+55"
        |> Message.new()
        |> Message.image("https://img.com/a.png", caption: "Look!")
        |> Meta.serialize()

      assert payload.type == "image"
      assert payload.image == %{link: "https://img.com/a.png", caption: "Look!"}
    end

    test "serializes a document" do
      payload =
        "+55"
        |> Message.new()
        |> Message.document("https://d.com/f.pdf", "invoice.pdf")
        |> Meta.serialize()

      assert payload.type == "document"
      assert payload.document == %{link: "https://d.com/f.pdf", filename: "invoice.pdf"}
    end

    test "serializes audio" do
      payload =
        "+55"
        |> Message.new()
        |> Message.audio("https://a.com/audio.ogg")
        |> Meta.serialize()

      assert payload.type == "audio"
      assert payload.audio == %{link: "https://a.com/audio.ogg"}
    end

    test "serializes sticker" do
      payload =
        "+55"
        |> Message.new()
        |> Message.sticker("https://s.com/s.webp")
        |> Meta.serialize()

      assert payload.type == "sticker"
      assert payload.sticker == %{link: "https://s.com/s.webp"}
    end
  end

  describe "serialize/1 — location messages" do
    test "serializes location" do
      payload =
        "+55"
        |> Message.new()
        |> Message.location(-23.55, -46.63, name: "SP")
        |> Meta.serialize()

      assert payload.type == "location"
      assert payload.location.latitude == -23.55
      assert payload.location.longitude == -46.63
      assert payload.location.name == "SP"
    end
  end

  describe "serialize/1 — reaction messages" do
    test "serializes a reaction" do
      payload =
        "+55"
        |> Message.new()
        |> Message.react("👍", message_id: "wamid.123")
        |> Meta.serialize()

      assert payload.type == "reaction"
      assert payload.reaction == %{emoji: "👍", message_id: "wamid.123"}
    end
  end

  describe "serialize/1 — template messages" do
    test "serializes a simple template" do
      payload =
        "+55"
        |> Message.new()
        |> Message.template("hello_world", "en_US")
        |> Meta.serialize()

      assert payload.type == "template"
      assert payload.template.name == "hello_world"
      assert payload.template.language == %{code: "en_US"}
    end

    test "serializes a template with body parameters" do
      payload =
        "+55"
        |> Message.new()
        |> Message.template("order", "en_US", [
          Template.body_param("John"),
          Template.body_param("#123")
        ])
        |> Meta.serialize()

      body_component = Enum.find(payload.template.components, &(&1.type == "body"))
      assert body_component.parameters == [%{type: "text", text: "John"}, %{type: "text", text: "#123"}]
    end

    test "serializes a template with header image" do
      payload =
        "+55"
        |> Message.new()
        |> Message.template("promo", "en_US", [
          Template.header_image("https://img.com/promo.png"),
          Template.body_param("50% off")
        ])
        |> Meta.serialize()

      header = Enum.find(payload.template.components, &(&1.type == "header"))
      assert [%{type: "image", image: %{link: "https://img.com/promo.png"}}] = header.parameters
    end
  end
end
