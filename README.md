# anu

[![Hex.pm](https://img.shields.io/hexpm/v/anu.svg)](https://hex.pm/packages/anu)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/anu)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Composable Elixir SDK for the WhatsApp Business API.

Anu is an open core platform for building on WhatsApp. This repo contains the Elixir SDK — the first official client. TypeScript, Python, and Go SDKs are coming.

**[Docs](https://anu.zeetech.io/docs)** · **[Landing page](https://anu.zeetech.io)** · **[Cloud](https://anu.zeetech.io/#pricing)**

## Quick look

```elixir
Anu.Message.new("5511999999999")
|> Anu.Message.text("Your order has shipped!")
|> Anu.Message.buttons([
  {"Track", :track_order},
  {"Cancel", :cancel}
])
|> Anu.deliver()
```

## Installation

Requires Elixir 1.19+ and OTP 27+.

Add `anu` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:anu, "~> 0.1"}
  ]
end
```

## Configuration

Anu talks directly to Meta's Cloud API. Bring your own token:

```elixir
# config/config.exs
config :anu,
  access_token: System.get_env("WHATSAPP_ACCESS_TOKEN"),
  phone_number_id: System.get_env("WHATSAPP_PHONE_NUMBER_ID"),
  verify_token: System.get_env("WHATSAPP_VERIFY_TOKEN")
```

### Finch pool

Anu uses Finch for HTTP. You can configure the connection pool to tune concurrency for your workload:

```elixir
# config/config.exs
config :anu, :finch_pool,
  size: 50,
  count: 4
```

Or start a named Finch instance and pass it in:

```elixir
# In your application supervisor
children = [
  {Finch, name: MyApp.Finch, pools: %{
    "https://graph.facebook.com" => [size: 100, count: 8]
  }}
]

# config/config.exs
config :anu, finch: MyApp.Finch
```

## Usage

### Composing messages

Messages are built by piping through composable functions — no macros, no DSLs:

```elixir
# Simple text
Anu.Message.new(to)
|> Anu.Message.text("Hello!")
|> Anu.deliver()

# Rich interactive message
Anu.Message.new(to)
|> Anu.Message.header_image("https://example.com/menu.jpg")
|> Anu.Message.body("Check out our new menu")
|> Anu.Message.footer("Open daily 8am–10pm")
|> Anu.Message.buttons([
  {"Order now", :order},
  {"View hours", :hours}
])
|> Anu.deliver()

# List message with sections
Anu.Message.new(to)
|> Anu.Message.body("What can I help you with?")
|> Anu.Message.button_text("Choose an option")
|> Anu.Message.sections([
  Anu.Section.new("Orders", [
    Anu.Row.new("order_status", "Order status"),
    Anu.Row.new("order_cancel", "Cancel order")
  ]),
  Anu.Section.new("Account", [
    Anu.Row.new("account_info", "Account info"),
    Anu.Row.new("account_help", "Get help")
  ])
])
|> Anu.deliver()

# Location
Anu.Message.new(to)
|> Anu.Message.location(-23.5505, -46.6333, name: "São Paulo", address: "SP, Brazil")
|> Anu.deliver()

# React to a message
Anu.Message.new(to)
|> Anu.Message.react("👍", message_id: original_msg_id)
|> Anu.deliver()
```

### Templates

```elixir
Anu.Message.new(to)
|> Anu.Message.template("order_confirmation", "pt_BR", [
  Anu.Template.body_param("João"),
  Anu.Template.body_param("#12345")
])
|> Anu.deliver()
```

### Webhook handling

Drop the plug into your Phoenix router:

```elixir
# lib/my_app_web/router.ex
forward "/webhooks/whatsapp", Anu.Webhook.Plug,
  handler: MyApp.WhatsAppHandler
```

Implement the handler behaviour:

```elixir
defmodule MyApp.WhatsAppHandler do
  @behaviour Anu.Webhook.Handler

  @impl true
  def handle_event(:message_received, %Anu.Event.Message{} = msg) do
    msg.from
    |> Anu.Message.new()
    |> Anu.Message.react("👍")
    |> Anu.deliver()
  end

  @impl true
  def handle_event(:message_status, %Anu.Event.Status{} = status) do
    # status.id, status.status (:sent, :delivered, :read, :failed)
    :ok
  end

  @impl true
  def handle_event(_event, _payload), do: :ok
end
```

### Adapters

Like Swoosh, Anu supports multiple adapters:

```elixir
# config/config.exs

# Production — Meta Cloud API (default)
config :anu, adapter: Anu.Adapters.Meta

# Development — logs messages to console
config :anu, adapter: Anu.Adapters.Local

# Test — stores messages in-process
config :anu, adapter: Anu.Adapters.Test
```

In tests:

```elixir
use Anu.TestAssertions

test "sends order confirmation" do
  MyApp.send_confirmation(order)

  assert_message_sent %{to: order.customer_phone, text: ~r/shipped/}
end
```

## Anu Cloud

The open source SDK handles messaging and webhooks. [Anu Cloud](https://anu.zeetech.io) adds AI primitives and a workflow engine as a hosted API.

```elixir
# Add the cloud client
{:anu_cloud, "~> 0.1"}
```

### AI primitives

```elixir
# Classify intent
{:ok, %{intent: :order_status, confidence: 0.95}} =
  Anu.AI.classify(msg, intents: [:order_status, :complaint, :general])

# Generate contextual reply
Anu.Message.new(msg.from)
|> Anu.AI.reply(context: order_data, tone: :friendly)
|> Anu.deliver()

# Extract structured data
{:ok, %{name: "João", order_id: "12345"}} =
  Anu.AI.extract(msg, schema: %{name: :string, order_id: :string})

# Summarize conversation
{:ok, summary} = Anu.AI.summarize(conversation_id)
```

### Workflows

```elixir
Anu.Workflow.new("support")
|> Anu.Workflow.on_message(match: :any)
|> Anu.Workflow.step(:classify, &Anu.AI.classify(&1, intents: [:order, :billing, :other]))
|> Anu.Workflow.branch(%{
  order:   &Anu.AI.reply(&1, context: :orders_db),
  billing: &Anu.Workflow.handoff(&1, to: :human_agent),
  other:   &Anu.AI.reply(&1, fallback: true)
})
|> Anu.Workflow.deploy()
```

## Zero markup pricing

Anu does not mark up Meta's messaging fees. You pay Meta's per-message cost directly. The cloud service charges only for AI usage and the platform subscription.

## Other SDKs

This is the Elixir SDK. Other official SDKs are in development:

| SDK | Status | Repo |
|-----|--------|------|
| Elixir | Available | [zoedsoupe/anu](https://github.com/zeeetech/anu_ex) |
| TypeScript | Coming soon | — |
| Python | Coming soon | — |
| Go | Coming soon | — |

You can also use the [REST API](https://anu.zeetech.io/docs/rest) directly from any language.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a PR.

```bash
git clone https://github.com/zeeetech/anu_ex.git
cd anu
mix deps.get
mix test
```

---

Built with 💜 by [@zoedsoupe](https://github.com/zoedsoupe)
