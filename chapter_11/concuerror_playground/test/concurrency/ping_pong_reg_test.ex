Code.require_file "../test_helper.exs", __DIR__

defmodule PingPongReg.ConcurrencyTest do
  use ExUnit.Case
  import PingPongReg

  def test do

    {:ok, ping_pid} = start_ping
    {:ok, pong_pid} = start_pong

    # Kickstart the ping/pong session
    send(:ping, :pong)
    send(:pong, :stop)
    send(:ping, :stop)
  end

end
