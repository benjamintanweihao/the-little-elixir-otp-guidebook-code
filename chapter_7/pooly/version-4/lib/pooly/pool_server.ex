defmodule Pooly.PoolServer do
  use GenServer
  import Supervisor.Spec

  defmodule State do
    defstruct pool_sup: nil,
    worker_sup: nil,
    monitors: nil,
    monitors: nil,
    size: nil,
    workers: nil,
    name: nil,
    mfa: nil,
    waiting: nil,
    overflow: nil,
    max_overflow: nil
  end

  def start_link(pool_sup, pool_config) do
    GenServer.start_link(__MODULE__, [pool_sup, pool_config], name: name(pool_config[:name]))
  end

  def checkout(pool_name, block, timeout) do
    GenServer.call(name(pool_name), {:checkout, block}, timeout)
  end

  def checkin(pool_name, worker_pid) do
    GenServer.cast(name(pool_name), {:checkin, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(name(pool_name), :status)
  end

  #############
  # Callbacks #
  ############j

  def init([pool_sup, pool_config]) when is_pid(pool_sup) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    waiting  = :queue.new
    state    = %State{pool_sup: pool_sup, monitors: monitors, waiting: waiting, overflow: 0}

    init(pool_config, state)
  end

  def init([{:name, name}|rest], state) do
    init(rest,  %{state | name: name})
  end

  def init([{:mfa, mfa}|rest], state) do
    init(rest,  %{state | mfa: mfa})
  end

  def init([{:size, size}|rest], state) do
    init(rest, %{state | size: size})
  end

  def init([{:max_overflow, max_overflow}|rest], state) do
    init(rest, %{state | max_overflow: max_overflow})
  end

  def init([], state) do
    send(self, :start_worker_supervisor)
    {:ok, state}
  end

  def init([_|rest], state) do
    init(rest, state)
  end

  def handle_call({:checkout, block}, {from_pid, _ref} = from, state) do
    # NOTE: you _cannot_ write state = %{workers: worker}
    %{worker_sup:   worker_sup,
      workers:      workers,
      monitors:     monitors,
      waiting:      waiting,
      overflow:     overflow,
      max_overflow: max_overflow} = state

    case workers do
      [worker|rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] when max_overflow > 0 and overflow < max_overflow ->
        {worker, ref} = new_worker(worker_sup, from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | overflow: overflow+1}}

      [] when block == true ->
        ref = Process.monitor(from_pid)
        waiting = :queue.in({from, ref}, waiting)
        {:noreply, %{state | waiting: waiting}, :infinity}

      [] ->
        {:reply, :full, state};
    end
  end

  def handle_call(:status, _from, %{workers: workers, monitors: monitors} = state) do
    {:reply, {state_name(state), length(workers), :ets.info(monitors, :size)}, state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, {:error, :invalid_message}, :ok, state}
  end

  def handle_cast({:checkin, worker}, %{monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = handle_checkin(pid, state)
        {:noreply, new_state}

      [] ->
        {:noreply, state}
    end
  end

  def handle_info(:start_worker_supervisor, state = %{pool_sup: pool_sup, name: name, mfa: mfa, size: size}) do
    {:ok, worker_sup} = Supervisor.start_child(pool_sup, supervisor_spec(name, mfa))
    workers = prepopulate(size, worker_sup)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  def handle_info({:DOWN, ref, _, _, _}, state = %{monitors: monitors, workers: workers}) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] ->
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: [pid|workers]}
        {:noreply, new_state}

      [[]] ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, worker_sup, reason}, state = %{worker_sup: worker_sup}) do
    {:stop, reason, state}
  end

  def handle_info({:EXIT, pid, _reason}, state = %{monitors: monitors, workers: workers, worker_sup: worker_sup}) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = handle_worker_exit(pid, state)
        {:noreply, new_state}

      [] ->
        # NOTE: Worker crashed, no monitor
        case Enum.member?(workers, pid) do
          true ->
            remaining_workers = workers |> Enum.reject(fn(p) -> p == pid end)
            new_state = %{state | workers: [new_worker(worker_sup)|remaining_workers]}
            {:noreply, new_state}

            false ->
              {:noreply, state}
        end
    end
  end

  def handle_info(_info, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  #####################
  # Private Functions #
  #####################

  defp name(pool_name) do
    :"#{pool_name}Server"
  end

  defp prepopulate(size, sup) do
    prepopulate(size, sup, [])
  end

  defp prepopulate(size, _sup, workers) when size < 1 do
    workers
  end

  defp prepopulate(size, sup, workers) do
    prepopulate(size-1, sup, [new_worker(sup)|workers])
  end

  defp new_worker(sup) do
    {:ok, worker} = Supervisor.start_child(sup, [[]])
    true = Process.link(worker)
    worker
  end

  # NOTE: We use this when we have to queue up the consumer
  defp new_worker(sup, from_pid) do
    pid = new_worker(sup)
    ref = Process.monitor(from_pid)
    {pid, ref}
  end

  defp dismiss_worker(sup, pid) do
    true = Process.unlink(pid)
    Supervisor.terminate_child(sup, pid)
  end

  def handle_checkin(pid, state) do
    %{worker_sup:   worker_sup,
      workers:      workers,
      monitors:     monitors,
      waiting:      waiting,
      overflow:     overflow} = state

    case :queue.out(waiting) do
      {{:value, {from, ref}}, left} ->
        true = :ets.insert(monitors, {pid, ref})
        GenServer.reply(from, pid)
        %{state | waiting: left}

        # what case? this seems to handle an inconsistent state
        {:empty, empty} when overflow > 0 ->
        :ok = dismiss_worker(worker_sup, pid)
        %{state | waiting: empty, overflow: overflow-1}

      {:empty, empty} ->
        # NOTE: This is how we used to add workers back
        %{state | waiting: empty, workers: [pid|workers], overflow: 0}
    end
  end

  defp handle_worker_exit(pid, state) do
    %{worker_sup:   worker_sup,
      workers:      workers,
      monitors:     monitors,
      waiting:      waiting,
      overflow:     overflow} = state

    case :queue.out(waiting) do
      {{:value, {from, ref}}, left} ->
        new_worker = new_worker(worker_sup)
        true = :ets.insert(monitors, {new_worker, ref})
        GenServer.reply(from, new_worker)
        %{state | waiting: left}

      # NOTE: Dynamically create worker has exited. We don't
      # have to re-create it.
      {:empty, empty} when overflow > 0 ->
        %{state | overflow: overflow-1, waiting: empty}

      # NOTE: We need to create a another worker because this
      #       worker was _not_ dynamically created.
      {:empty, empty} ->
        workers = [new_worker(worker_sup) | workers |> Enum.reject(fn(p) -> p != pid end)]
        %{state | workers: workers, waiting: empty}
    end
  end

  defp supervisor_spec(name, mfa) do
    # NOTE: The reason this is set to temporary is because the WorkerSupervisor
    #       is started by the PoolServer.
    opts = [id: name <> "WorkerSupervisor", shutdown: 10000, restart: :temporary]
    supervisor(Pooly.WorkerSupervisor, [self, mfa], opts)
  end

  defp state_name(%State{overflow: overflow, max_overflow: max_overflow, workers: workers}) when overflow < 1 do
    case length(workers) == 0 do
      true ->
        if max_overflow < 1 do
          :full
        else
          :overflow
        end
      false ->
        :ready
    end
  end

  defp state_name(%State{overflow: max_overflow, max_overflow: max_overflow}) do
    :full
  end

  defp state_name(_state) do
    :overflow
  end

end
