# Contributing to Anu

Thanks for your interest in contributing to Anu! This guide will help you get started.

## Getting started

### Prerequisites

- Elixir 1.19+ and OTP 27+
- A WhatsApp Business API test account (optional, for integration tests)

### Setup

```bash
git clone https://github.com/zeeetech/anu-ex.git
cd anu
mix deps.get
mix test
```

### Running checks

Before submitting a PR, make sure everything passes:

```bash
mix format --check-formatted
mix credo --strict
mix dialyzer
mix test
```

## Project structure

```
anu/
├── lib/
│   ├── anu.ex                  # Main module, deliver/1 entry point
│   ├── anu/
│   │   ├── message.ex          # Message struct & composing functions
│   │   ├── section.ex          # List section builder
│   │   ├── row.ex              # List row builder
│   │   ├── template.ex         # Template message helpers
│   │   ├── webhook/
│   │   │   ├── plug.ex         # Phoenix plug for webhooks
│   │   │   ├── handler.ex      # Handler behaviour
│   │   │   └── signature.ex    # Webhook signature verification
│   │   ├── adapters/
│   │   │   ├── meta.ex         # Meta Cloud API adapter (production)
│   │   │   ├── local.ex        # Console logger adapter (dev)
│   │   │   └── test.ex         # In-process adapter (test)
│   │   ├── config.ex           # Runtime configuration
│   │   └── test_assertions.ex  # ExUnit assertion helpers
├── test/
│   ├── anu/
│   │   ├── message_test.exs
│   │   ├── webhook_test.exs
│   │   └── adapters/
│   ├── support/
│   │   └── fixtures.ex
│   └── test_helper.exs
├── mix.exs
└── README.md
```

## Design principles

Anu follows a few core principles. Please keep these in mind when contributing.

### Pipe-first composition

Every public function should work well in a pipeline. Functions that operate on a message take the message struct as the first argument and return the updated struct.

```elixir
# good - pipeable
Anu.Message.new(to)
|> Anu.Message.text("hello")
|> Anu.Message.buttons([{"OK", :ok}])

# avoid - nested or imperative
Anu.Message.buttons(Anu.Message.text(Anu.Message.new(to), "hello"), [{"OK", :ok}])
```

### No macros unless absolutely necessary

We prefer plain functions and structs over macros and DSLs. Macros are harder to debug, compose, and document. If you think a macro is needed, open an issue to discuss it first.

### Minimal dependencies

We keep the dependency tree as small as possible. Anu uses Elixir 1.19's native `JSON` module instead of third-party JSON libraries, and Finch directly for HTTP instead of higher-level wrappers. Before adding any new dependency, open an issue to justify it.

### Adapters for everything external

All external communication goes through adapter behaviours. This keeps the core library testable without hitting real APIs. If you're adding a new integration, define a behaviour and implement at least two adapters (real + test).

### Explicit over magic

Configuration should be explicit. Errors should be clear. No hidden state, no global mutable config, no surprise side effects. Use `{:ok, result}` / `{:error, reason}` tuples consistently.

## How to contribute

### Reporting bugs

Open an issue with:

- Elixir/OTP version
- Anu version
- Minimal reproduction steps
- Expected vs actual behavior

### Suggesting features

Open an issue describing the use case before writing code. This helps avoid wasted effort and lets us discuss the API design together.

### Submitting pull requests

1. Fork the repo and create your branch from `main`
2. Write your code and add tests
3. Make sure all checks pass (`mix format`, `mix credo`, `mix dialyzer`, `mix test`)
4. Write a clear PR description explaining what and why
5. Keep PRs focused - one feature or fix per PR

### Writing tests

- Unit tests go in `test/anu/` mirroring the `lib/anu/` structure
- Use the `Anu.Adapters.Test` adapter in tests, never hit real APIs
- Test the pipe composition - assert that functions return the correct struct
- For webhook tests, use the fixtures in `test/support/fixtures.ex`

### Documentation

- All public functions need `@doc` and `@spec`
- Include at least one code example in each `@doc`
- Run `mix docs` locally to preview hexdocs output

## Code style

We use `mix format` with the default config. Beyond that:

- Prefer pattern matching over conditionals when possible
- Use `with` for happy-path chains with multiple potential failures
- Keep functions short - if it needs a comment explaining a section, extract a function
- Name variables descriptively - `message` not `m`, `phone_number` not `pn`

## Community

- Be kind and respectful
- Assume good intent
- Help others learn - not everyone has the same background
- All contributions matter - docs, tests, bug reports, and code are equally valued

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
