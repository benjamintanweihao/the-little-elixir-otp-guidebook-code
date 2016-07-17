defmodule Blitzy.Mixfile do
  use Mix.Project

  def project do
    [app: :blitzy,
     version: "0.0.1",
     elixir: "~> 1.1",
     escript: escript,
     deps: deps]
  end

  def escript do
    [main_module: Blitzy.CLI]
  end

  def application do
    [mod: {Blitzy, []},
     applications: [:logger, :httpoison, :timex]]
  end

  defp deps do
    [
      {:httpoison, "~> 0.9.0"},
      {:timex,     "~> 3.0"},
      {:tzdata, "~> 0.1.8", override: true}
    ]
  end
end
