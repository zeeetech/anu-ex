defmodule Anu.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/zeeetech/anu-ex"

  def project do
    [
      app: :anu,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Anu",
      description: "Composable Elixir SDK for the WhatsApp Business API",
      source_url: @source_url,
      homepage_url: "https://anu.zeetech.io",
      package: package(),
      docs: docs(),
      dialyzer: [plt_add_apps: [:mix, :ex_unit]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:finch, "~> 0.19"},
      {:plug, "~> 1.16"},
      {:mox, "~> 1.2", only: :test},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false},
      {:styler, "~> 1.11", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      quality: ["format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CONTRIBUTING.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CONTRIBUTING.md", "LICENSE"],
      source_ref: "v#{@version}"
    ]
  end
end
