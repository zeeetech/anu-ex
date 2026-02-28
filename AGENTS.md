# AGENTS.md

This file provides context for AI coding agents (Claude Code, Cursor, Copilot, etc.) working on the Anu codebase.

## Project overview

Anu is an open core platform for building on WhatsApp. It provides composable message building, webhook handling, and AI primitives for the WhatsApp Business API.

The platform has three layers:

- **SDKs** (open source, MIT) — client libraries for multiple languages. This repo is the Elixir SDK, which is the reference implementation. TypeScript, Python, and Go SDKs will follow.
- **REST API** — language-agnostic HTTP API for messaging, AI, and workflows. The SDKs are thin wrappers around this API for the OSS features, and the cloud features are only accessible via the API.
- **Cloud** (proprietary, hosted) — AI primitives and workflow engine, powered by Anthropic Claude.

## Tech stack (Elixir SDK)

- **Language**: Elixir 1.19+, OTP 27+
- **HTTP client**: Finch (direct, no high-level wrappers)
- **JSON**: Elixir 1.19 native `JSON` module (no Jason, no Poison)
- **Web**: Plug (for webhooks — framework-agnostic, works with Phoenix, Bandit, etc.)
- **Testing**: ExUnit, Mox for adapter mocks
- **Code quality**: Credo (strict), Dialyzer, `mix format`

## Architecture decisions

### Pipe-first, no macros

All public API functions take the primary struct as the first argument and return the updated struct. This enables `|>` composition. We do not use macros or DSLs for the public API. Internal macros are acceptable only for reducing boilerplate in adapter implementations.

### Finch for HTTP, not Req/HTTPoison/Tesla

We use Finch directly for maximum control over connection pooling. Users can configure pool size and count, or pass their own named Finch instance. This matters for a messaging gateway where connection management directly affects throughput.

The Finch pool is configurable:

```elixir
# Default pool managed by Anu
config :anu, :finch_pool, size: 50, count: 4

# Or bring your own Finch instance
config :anu, finch: MyApp.Finch
```

When making HTTP calls in adapters, always use `Anu.Config.finch_name()` to resolve the Finch instance, never hardcode a name.

### Native JSON, no Jason

Elixir 1.19 ships with the `JSON` module. We use it exclusively. Do not add Jason, Poison, or any other JSON library as a dependency. Use `JSON.encode!/1` and `JSON.decode!/1` for internal encoding. For structs that need custom serialization, implement the `JSON.Encoder` protocol.

### Adapter pattern

External I/O is abstracted behind behaviours:

```
Anu.Adapter (behaviour)
├── Anu.Adapters.Meta   — production, hits Meta Cloud API via Finch
├── Anu.Adapters.Local  — dev, logs to console
└── Anu.Adapters.Test   — test, stores in process mailbox
```

The adapter is resolved at runtime via config, not compile time. This allows per-test adapter overrides.

### Message struct

`Anu.Message` is a plain struct, not an Ecto schema. It accumulates state as the developer pipes through builder functions. The struct is only serialized to the Meta API format when `Anu.deliver/1` is called. This means validation happens at delivery time, not at build time — keeping the composing API lenient and the delivery strict.

### Webhook handling

`Anu.Webhook.Plug` is a standalone Plug (not a Phoenix controller) so it works in any Plug-based app. It verifies the webhook signature, parses the payload into event structs, and dispatches to the user's handler module via the `Anu.Webhook.Handler` behaviour.

### Error handling

Functions that can fail return `{:ok, result} | {:error, reason}` tuples. `Anu.deliver/1` returns `{:ok, response}` or `{:error, %Anu.Error{}}`. We also provide bang variants (`Anu.deliver!/1`) that raise on error for use in scripts and IEx.

## Code conventions

### Naming

- Modules: `Anu.Message`, `Anu.Section`, `Anu.Row` (singular nouns)
- Functions: verb-first for actions (`deliver`, `classify`, `extract`), noun for builders (`text`, `buttons`, `header_image`)
- Variables: descriptive, no abbreviations. `message` not `msg`, `phone_number` not `pn`
- Test files: mirror `lib/` structure with `_test.exs` suffix

### Patterns to follow

```elixir
# Builder functions — always return the struct
@spec text(t(), String.t()) :: t()
def text(%Message{} = message, body) when is_binary(body) do
  %{message | body: body}
end

# Delivery — returns ok/error tuple
@spec deliver(Message.t()) :: {:ok, Response.t()} | {:error, Error.t()}
def deliver(%Message{} = message) do
  adapter = Config.adapter()
  adapter.deliver(message, Config.finch_name())
end

# HTTP calls — always go through Finch, always use Config
@spec send_request(map()) :: {:ok, Finch.Response.t()} | {:error, term()}
defp send_request(payload) do
  url = "https://graph.facebook.com/v21.0/#{Config.phone_number_id()}/messages"

  Finch.build(:post, url, headers(), JSON.encode!(payload))
  |> Finch.request(Config.finch_name())
end
```

### Patterns to avoid

- Don't use `Application.get_env/3` directly — use `Anu.Config` module
- Don't use macros for public API functions
- Don't add deps without discussing first — we keep the dependency tree minimal
- Don't use Jason, Poison, or any JSON lib — use native `JSON` module
- Don't use Req, HTTPoison, or Tesla — use `Finch` directly
- Don't put business logic in the Plug — the Plug only parses and dispatches
- Don't use atoms for user-provided strings (atom table exhaustion risk)
- Don't hardcode the Finch instance name — always go through `Config.finch_name()`

## Testing

### Running tests

```bash
mix test                    # all tests
mix test test/anu/message_test.exs  # single file
mix test --only integration # integration tests (needs API credentials)
```

### Writing tests

- Default adapter in test env is `Anu.Adapters.Test`
- Use `Anu.TestAssertions` for delivery assertions
- Webhook tests use fixture payloads from `test/support/fixtures.ex`
- Integration tests are tagged `@tag :integration` and skipped by default
- For Finch-level tests, use `Mox` to mock the adapter, don't mock Finch itself

```elixir
use Anu.TestAssertions

test "sends text message" do
  Anu.Message.new("+5511999999999")
  |> Anu.Message.text("hello")
  |> Anu.deliver()

  assert_message_sent %{to: "+5511999999999", body: "hello"}
end
```

## File structure

```
lib/
├── anu.ex                     # deliver/1, deliver!/1, main entry point
├── anu/
│   ├── message.ex             # Message struct + all builder functions
│   ├── section.ex             # Section struct for list messages
│   ├── row.ex                 # Row struct for list items
│   ├── template.ex            # Template message helpers
│   ├── response.ex            # API response struct
│   ├── error.ex               # Error struct
│   ├── config.ex              # Runtime config resolution (adapter, finch, tokens)
│   ├── adapter.ex             # Adapter behaviour definition
│   ├── adapters/
│   │   ├── meta.ex            # Meta Cloud API (Finch-based)
│   │   ├── local.ex           # Console logger
│   │   └── test.ex            # In-process test adapter
│   ├── webhook/
│   │   ├── plug.ex            # Plug for incoming webhooks
│   │   ├── handler.ex         # Handler behaviour
│   │   ├── parser.ex          # Payload parsing to event structs
│   │   └── signature.ex       # HMAC signature verification
│   ├── event/
│   │   ├── message.ex         # Inbound message event struct
│   │   └── status.ex          # Message status event struct
│   └── test_assertions.ex     # ExUnit helpers
```

## Key dependencies

- `finch` — HTTP client with connection pooling
- `plug` — webhook handling (framework-agnostic)
- `mox` — test mocks for adapters (dev/test only)
- `ex_doc` — documentation (dev only)
- `credo` — linting (dev only)
- `dialyxir` — type checking (dev only)

Note: JSON encoding uses Elixir 1.19's native `JSON` module. No JSON library dependency.

## Common tasks

### Adding a new message type

1. Add builder function to `Anu.Message` with `@spec` and `@doc`
2. Update serialization in `Anu.Adapters.Meta` to handle the new type (use `JSON.encode!/1`)
3. Add tests in `test/anu/message_test.exs`
4. Add fixture in `test/support/fixtures.ex` if it has a webhook counterpart

### Adding a new adapter

1. Implement the `Anu.Adapter` behaviour
2. Receive the Finch instance name as a parameter if the adapter does HTTP
3. Add to the adapter docs in README
4. Add tests using the adapter directly (not through `Anu.deliver/1`)

### Adding a new webhook event

1. Create event struct in `lib/anu/event/`
2. Add parsing logic in `Anu.Webhook.Parser` (use `JSON.decode!/1` for payloads)
3. Add callback clause to `Anu.Webhook.Handler` behaviour
4. Add fixture payload in `test/support/fixtures.ex`

### Changing Finch pool defaults

Pool defaults live in `Anu.Config`. If you need to change them, update the defaults there and document the change. The user can always override via config or by passing their own Finch instance.
