Code.require_file "../test_helper.exs", __DIR__

defmodule SpawnReg.ConcurrencyTest do
  use ExUnit.Case

  def test do
    spawn(fn -> SpawnReg.start end)
    send(SpawnReg, :stop)

    # The race condition here happens because
    # the process might not complete setting name up yet.
    # Therefore, send/2 might fail if `:name` 
    # is not registered yet
  end

end
