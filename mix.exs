defmodule Web3MoveExExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :web3_move_ex_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
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
      {:web3_move_ex, "~> 0.4.0"},
      {:web3_aptos_ex, "~> 1.0.6"},
      {:eth_wallet, "~> 0.1.0"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
