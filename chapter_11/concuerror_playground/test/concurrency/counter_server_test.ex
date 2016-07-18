defmodule CounterServer.ConcurrencyTest do

  def test do
    {:ok, _pid} = CounterServer.start_link
    CounterServer.set(10)
    CounterServer.count_down
  end

end
