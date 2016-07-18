defmodule OthersEQC do
  use ExUnit.Case
  use EQC.ExUnit

  property "encoding then decoding a binary gives back the same binary" do
    forall s <- binary do
      equal s |> Base.encode16 |> Base.decode16!, s
    end
  end

  def equal(x, y) do
    when_fail(IO.puts("FAILED ☛ #{inspect(x)} != #{inspect(y)}")) do
      x == y
    end
  end

end
