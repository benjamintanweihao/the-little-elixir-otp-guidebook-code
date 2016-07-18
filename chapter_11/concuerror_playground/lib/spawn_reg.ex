defmodule SpawnReg do

  @name __MODULE__

  def start do
    case Process.whereis(@name) do
      nil ->
        pid = spawn(fn -> loop end)
        Process.register(pid, @name)
        :ok
      _ ->
        :already_started
    end
  end

  def loop do
    receive do
      :stop ->
        :ok
      _ -> 
        loop
    end
  end

end
