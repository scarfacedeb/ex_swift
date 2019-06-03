defmodule ExSwift.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_swift,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExSwift.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mojito, "~> 0.3"},
      {:jason, "~> 1.1"},
      {:typed_struct, "~> 0.1"}
    ]
  end
end
