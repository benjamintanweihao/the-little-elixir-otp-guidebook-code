defmodule Metex.Coordinator do

  def loop(results \\ [], results_expected) do
    receive do
      {:ok, result} ->
        new_results = [result|results]
        if results_expected == Enum.count(new_results) do
          send self, :exit
        end
        loop(new_results, results_expected) 
      :exit ->
        IO.puts(results |> Enum.sort |> Enum.join(", "))
      _ ->
        loop(results, results_expected)
    end
  end

end
