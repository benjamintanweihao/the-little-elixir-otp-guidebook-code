defmodule Chucky.Mixfile do
  use Mix.Project

  def project do
    [app: :chucky,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger],
       # registered: [Chucky, Chucky.Supervisor, Chucky.Server],
              mod: {Chucky, []}]
  end

  defp deps do
    []
  end

end
