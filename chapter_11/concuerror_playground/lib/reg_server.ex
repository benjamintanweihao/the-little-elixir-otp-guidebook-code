defmodule RegServer do
  @reg_name    __MODULE__
  @reg_request :reg_request
  @reg_reply   :reg_reply

  def start do
    pid = spawn(fn -> loop end)
    Process.register(pid, @reg_name)
    :ok
  end

  def ping do
    request(:ping)
  end

  def stop do
    request(:stop)
  end

  def loop do
    receive do
      {@reg_request, target, :ping} ->
        reply(target, :pong)
        loop

      {@reg_request, target, :stop} ->
        Process.unregister(@reg_name)
        reply(target, :ok)
    end
  end

  defp request(request) do
    case Process.whereis(@reg_name) do
      nil ->
        :server_down

      pid ->
        ref = Process.monitor(pid)
        send(pid, {@reg_request, self, request})
        receive do
          {@reg_reply, reply} -> 
            Process.demonitor(ref, [:flush])
            reply

          {:DOWN, ^ref, :process, ^pid, _reason} ->
            :server_down

        end
    end
  end

  defp reply(target, reply) do
    send(target, {@reg_reply, reply})
  end

end
