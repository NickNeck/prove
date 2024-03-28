defmodule Prove.MixProject do
  use Mix.Project

  @github "https://github.com/hrzndhrn/prove"
  @version "0.1.7"
  @description "Prove provides the macros `prove` and `batch` to write simple tests shorter."

  def project do
    [
      app: :prove,
      version: @version,
      elixir: "~> 1.12",
      name: "Prove",
      description: @description,
      source_url: @github,
      start_permanent: Mix.env() == :prod,
      docs: docs(),
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

  defp docs do
    [
      main: "Prove",
      source_ref: "v#{@version}",
      formatters: ["html"]
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
