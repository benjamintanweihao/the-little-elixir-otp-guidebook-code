defmodule Pooly.WorkerSupervisor do
  use Supervisor

  def start_link(pool_server, {_,_,_} = mfa) do
    Supervisor.start_link(__MODULE__, [pool_server, mfa])
  end

  def init([pool_server, {m,f,a}]) do
    Process.link(pool_server)
    worker_opts = [shutdown: 5000,
                   function: f]

    children = [worker(m, a, worker_opts)]
    opts     = [strategy:    :simple_one_for_one,
                max_restarts: 5,
                max_seconds:  5]

    supervise(children, opts)
  end

end
