# anu

[![Hex.pm](https://img.shields.io/hexpm/v/anu.svg)](https://hex.pm/packages/anu)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/anu)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Composable Elixir SDK for the WhatsApp Business Cloud API.

**[Docs](https://anu.zeetech.io/docs)** · **[Landing page](https://anu.zeetech.io)**

## Installation

Requires Elixir 1.19+ and OTP 27+.

```elixir
def deps do
  [
    {:anu, "~> 0.1"}
  ]
end
```

Anu does not start any processes. Start a Finch instance in your own
supervision tree:

```elixir
children = [
  {Finch, name: MyApp.Finch}
]
```

## Quick start

Delivery always goes through an explicit `Anu.Client` holding the
credentials for one WhatsApp phone number:

```elixir
client =
  Anu.Client.new(
    finch: MyApp.Finch,
    access_token: System.fetch_env!("WHATSAPP_ACCESS_TOKEN"),
    phone_number_id: System.fetch_env!("WHATSAPP_PHONE_NUMBER_ID")
  )

Anu.Message.new("5511999999999")
|> Anu.Message.text("Your order has shipped!")
|> Anu.Message.buttons([
  {"Track", :track_order},
  {"Cancel", :cancel}
])
|> Anu.deliver(client)
```

## Multiple numbers / WABAs

Build one client per phone number (or per WABA, when you hold several
access tokens) and deliver through the matching one:

```elixir
support = Anu.Client.new(finch: MyApp.Finch, access_token: "EAAG...", phone_number_id: "111")
sales   = Anu.Client.new(finch: MyApp.Finch, access_token: "EAAG...", phone_number_id: "222")

Anu.Message.new(to) |> Anu.Message.text("hi") |> Anu.deliver(support)
```

See `Anu.Client` for all options (`:adapter`, `:api_version`, `:cloud_url`,
`:cloud_api_key`).

## Composing messages

Messages are built by piping through composable functions, with no macros
or DSLs:

```elixir
# Rich interactive message
Anu.Message.new(to)
|> Anu.Message.header_image("https://example.com/menu.jpg")
|> Anu.Message.body("Check out our new menu")
|> Anu.Message.footer("Open daily 8am-10pm")
|> Anu.Message.buttons([
  {"Order now", :order},
  {"View hours", :hours}
])
|> Anu.deliver(client)

# List message with sections
Anu.Message.new(to)
|> Anu.Message.body("What can I help you with?")
|> Anu.Message.button_text("Choose an option")
|> Anu.Message.sections([
  Anu.Section.new("Orders", [
    Anu.Row.new("order_status", "Order status"),
    Anu.Row.new("order_cancel", "Cancel order")
  ])
])
|> Anu.deliver(client)

# Location
Anu.Message.new(to)
|> Anu.Message.location(-23.5505, -46.6333, name: "Sao Paulo", address: "SP, Brazil")
|> Anu.deliver(client)

# React to a message
Anu.Message.new(to) |> Anu.Message.react("👍", message_id: original_msg_id) |> Anu.deliver(client)

# Template
Anu.Message.new(to)
|> Anu.Message.template("order_confirmation", "pt_BR", [
  Anu.Template.body_param("Joao"),
  Anu.Template.body_param("#12345")
])
|> Anu.deliver(client)
```

## Webhook handling

Drop the plug into your Phoenix or Plug router:

```elixir
forward "/webhooks/whatsapp", Anu.Webhook.Plug,
  handler: MyApp.WhatsAppHandler,
  secret: System.fetch_env!("WHATSAPP_APP_SECRET"),
  verify_token: System.fetch_env!("WHATSAPP_VERIFY_TOKEN")
```

`:secret` and `:verify_token` are optional and fall back to
`config :anu, app_secret: ...` / `config :anu, verify_token: ...`. In
multi-app setups, mount one `forward` per app with its own secrets.

Inbound events carry `phone_number_id` and `display_phone_number` from the
payload metadata, so you can route them back to the right client.

Implement the handler behaviour:

```elixir
defmodule MyApp.WhatsAppHandler do
  @behaviour Anu.Webhook.Handler

  @impl true
  def handle_event(:message_received, %Anu.Event.Message{} = msg) do
    msg.from
    |> Anu.Message.new()
    |> Anu.Message.text("Thanks!")
    |> Anu.deliver(client_for(msg.phone_number_id))
  end

  def handle_event(_event, _payload), do: :ok
end
```

## AI primitives (`Anu.AI`)

Optional cloud-backed AI helpers (`classify/3`, `extract/3`, `reply/3`,
`summarize/2`) powered by [anu_cloud](https://anu.zeetech.io). Put your
`anu_sk_...` key on the client:

```elixir
client =
  Anu.Client.new(
    finch: MyApp.Finch,
    access_token: "...",
    phone_number_id: "...",
    cloud_api_key: System.fetch_env!("ANU_API_KEY")
  )

{:ok, %{"intent" => intent}} =
  Anu.AI.classify("my order is late", [intents: ["support", "sales", "spam"]], client)

{:ok, %{"reply" => reply}} = Anu.AI.reply("when does my package arrive?", [tone: "warm"], client)
```

All `Anu.AI` functions return `{:ok, decoded_map}` (string keys) or
`{:error, %Anu.Error{} | :cloud_not_configured}`. See `Anu.AI` for the full
reference.

## Adapters

Like Swoosh, Anu supports multiple adapters, chosen per client:

```elixir
# Production - Meta Cloud API (default)
Anu.Client.new(finch: MyApp.Finch, access_token: "...", phone_number_id: "...")

# Development - logs messages to console
Anu.Client.new(adapter: Anu.Adapters.Local, finch: MyApp.Finch)

# Test - stores messages in-process
Anu.Client.new(adapter: Anu.Adapters.Test, finch: MyApp.Finch)
```

In tests:

```elixir
import Anu.TestAssertions

test "sends order confirmation" do
  client = Anu.Client.new(adapter: Anu.Adapters.Test, finch: MyApp.Finch)

  MyApp.send_confirmation(order, client)

  assert_message_sent(to: order.customer_phone, body: "Your order has shipped!")
end
```

---

Built with 💜 by [@zoedsoupe](https://github.com/zoedsoupe)
