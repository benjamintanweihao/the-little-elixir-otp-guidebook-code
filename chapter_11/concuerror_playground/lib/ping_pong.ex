defmodule PingPong do

  def ping do
    receive do
      :pong -> :ok
    end
  end

  def pong(ping_pid) do
    send(ping_pid, :pong)
    receive do
      :ping -> :ok
    end
  end

end
