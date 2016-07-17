defmodule Metex.Mixfile do
  use Mix.Project

  def project do
    [app: :metex,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp deps do
    [ 
      {:httpoison, "~> 0.9.0"},
      {:json,      "~> 0.3.0"}
    ]
  end

end
