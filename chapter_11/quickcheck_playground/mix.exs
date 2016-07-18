defmodule QuickcheckPlayground.Mixfile do
  use Mix.Project

  def project do
    [app: :quickcheck_playground,
     version: "0.0.1",
     elixir: "~> 1.2-rc",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_pattern: "*_{test,eqc}.exs",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:eqc_ex, "~> 1.2.4"} 
    ]
  end
end
