defmodule Stacky do
  use GenServer
  require Integer

  @name __MODULE__

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def add(item) do
    GenServer.call(@name, {:add, item})
  end

  def tag(item) do
    GenServer.call(@name, {:tag, item})
  end

  def stop do
    GenServer.call(@name, :stop)
  end

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:add, item}, _from, state) do
    new_state = [item|state]
    {:reply, {:ok, new_state}, new_state} 
  end

  def handle_call({:tag, item}, _from, state) when Integer.is_even(item) do
    new_state = [{:even, item} |state]
    {:reply, {:ok, new_state}, new_state} 
  end

  def handle_call({:tag, item}, _from, state) when Integer.is_odd(item) do
    new_state = [{:odd, item} |state]
    {:reply, {:ok, new_state}, new_state} 
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason, _state) do
    :ok 
  end 

end
