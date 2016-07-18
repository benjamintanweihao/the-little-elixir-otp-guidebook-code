defmodule PingPongReg do

  def start_ping do
    start_and_reg_proc(:ping, ping)
  end

  def start_pong do
    start_and_reg_proc(:pong, pong)
  end

  def start_and_reg_proc(name, fun) when is_atom(name) do
    case Process.whereis(name) do
      nil ->
        pid = spawn(name, fun, [])
        Process.register(name, pid)
        {:ok, pid}
      pid ->
        {:error, :already_started}
    end
  end

  def ping do
    receive do
      :pong -> 
        IO.puts "pong"  
        send(:pong, :ping)
        ping
      :stop ->
        :ok
    end
  end

  def pong do
    receive do
      :ping -> 
        IO.puts "ping"  
        send(:ping, :pong)
        pong
      :stop ->
        :ok
    end
  end

end
