defmodule Prove.MixProject do
  use Mix.Project

  @github "https://github.com/hrzndhrn/prove"

  def project do
    [
      app: :prove,
      version: "0.1.4",
      elixir: "~> 1.11",
      name: "Prove",
      description: description(),
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/hrzndhrn/prove",
      package: package(),
      deps: deps()
    ]
  end

  def description do
    "Prove provides the macros `prove` and `batch` to write simple tests shorter."
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Marcus Kruse"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.25", only: :dev, runtime: false}
    ]
  end
end
