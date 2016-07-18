Code.require_file "../test_helper.exs", __DIR__

defmodule SpawnReg.ConcurrencyTest do

  def test do
    spawn(fn -> SpawnReg.start end)
    send(SpawnReg, :stop)
  end

end
