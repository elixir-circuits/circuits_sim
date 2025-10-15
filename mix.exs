defmodule CircuitsSim.MixProject do
  use Mix.Project

  @version "0.1.2"
  @description "Simulated hardware for Elixir Circuits"
  @source_url "https://github.com/elixir-circuits/circuits_sim"

  def project do
    [
      app: :circuits_sim,
      version: @version,
      elixir: "~> 1.13",
      description: @description,
      package: package(),
      source_url: @source_url,
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      dialyzer: [
        flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs]
      ],
      deps: deps(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {CircuitsSim.Application, []}
    ]
  end

  defp package do
    [
      files: [
        "CHANGELOG.md",
        "lib",
        "LICENSES",
        "mix.exs",
        "NOTICE",
        "README.md",
        "REUSE.toml"
      ],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "REUSE Compliance" =>
          "https://api.reuse.software/info/github.com/elixir-circuits/circuits_sim"
      }
    ]
  end

  defp deps() do
    [
      {:circuits_i2c, "~> 2.0"},
      {:circuits_spi, "~> 2.0"},
      {:circuits_gpio, "~> 2.0"},
      {:kino, "~> 0.14", optional: true},
      {:bmp280, "~> 0.2.12", only: [:dev, :test]},
      {:bmp3xx, "~> 0.1.5", only: [:dev, :test]},
      {:sgp30, github: "jjcarstens/sgp30", branch: "main", only: [:dev, :test]},
      {:cerlc, "~> 0.2.1"},
      {:aht20, "~> 0.4.0", only: [:dev, :test]},
      {:sht4x, "~> 0.2.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:credo_binary_patterns, "~> 0.2.2", only: :dev, runtime: false},
      {:dialyxir, "~> 1.2", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
