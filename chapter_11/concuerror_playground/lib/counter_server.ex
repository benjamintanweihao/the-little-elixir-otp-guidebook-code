defmodule CounterServer do
  use GenServer

  @server __MODULE__
  @table :table

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server)
  end

  def count_down do
    GenServer.call(@server, :count_down)
  end

  def set(n) do
    GenServer.cast(@server, {:set, n})
  end

  def init([]) do
    :ets.new(@table, [:named_table, :public])
    :ets.insert(@table, {:counter, 0})
    {:ok, 0}
  end

  def handle_call(:count_down, _from, state) do
    [{:counter, n}] = :ets.lookup(@table, :counter)
    case n do
      0 -> :ok
      _ ->
        :ets.insert(@table, {:counter, n-1})
        GenServer.call(@server, :count_down, :infinity)
    end
    {:reply, 0, state}
  end

  def handle_cast({:set, n}, state) do
    :ets.insert(@table, {:counter, n})
    {:noreply, state}
  end

end
