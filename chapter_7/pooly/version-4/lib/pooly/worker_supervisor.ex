defmodule Pooly.WorkerSupervisor do
  use Supervisor

  def start_link(pool_server, {_,_,_} = mfa) do
    Supervisor.start_link(__MODULE__, [pool_server, mfa])
  end

  def init([pool_server, {m,f,a}]) do
    Process.link(pool_server)
    # NOTE: Restart temporary means that we don't let the
    #       supervisor restart the worker. Instead, the
    #       PoolServer handle it instead.
    worker_opts = [restart: :temporary,
                   shutdown: 5000,
                   function: f]

    children = [worker(m, a, worker_opts)]
    opts     = [strategy:    :simple_one_for_one,
                max_restart: 5,
                max_time:    3600]

    supervise(children, opts)
  end

end
