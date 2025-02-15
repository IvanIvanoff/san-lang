defmodule SanLang.MixProject do
  use Mix.Project

  def project do
    [
      app: :san_lang,
      version: "0.1.0",
      elixir: "~> 1.18-dev",
      start_permanent: Mix.env() == :prod,
      compilers: [:leex, :yecc] ++ Mix.compilers(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rexbug, ">= 2.0.0-rc1", only: [:dev]}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
