defmodule Logoot.Mixfile do
  use Mix.Project

  @version "1.0.2"

  def project do
    [app: :logoot,
     description: "An implementation of the Logoot CRDT",
     package: package,
     docs: docs,
     source_url: "https://github.com/usecanvas/logoot_ex",
     homepage_url: "https://github.com/usecanvas/logoot_ex",
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     dialyzer: [plt_add_deps: true],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :uuid]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:uuid, "~> 1.1"},
     {:dialyxir, "~> 0.3.5", only: [:dev]},
     {:ex_doc, "> 0.0.0", only: [:dev]}]
  end

  defp package do
    [maintainers: ["Jonathan Clem <jonathan@usecanvas.com>"],
     licenses: ["MIT"],
     links: %{GitHub: "https://github.com/usecanvas/logoot_ex"},
     files: ~w(lib mix.exs LICENSE.md README.md)]
  end

  defp docs do
    [source_ref: "v#{@version}",
     main: "readme",
     extras: ~w(README.md LICENSE.md)]
  end
end
