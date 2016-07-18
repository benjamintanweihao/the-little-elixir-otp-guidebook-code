Code.require_file "../test_helper.exs", __DIR__

defmodule PingPong.ConcurrencyTest do
  use ExUnit.Case

  def test do
    ping_pid = spawn(fn -> PingPong.ping end)
    spawn(fn -> PingPong.pong(ping_pid) end)
  end

end
