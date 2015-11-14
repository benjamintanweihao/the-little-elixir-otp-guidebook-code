Pooly
=====

![](http://i.imgur.com/NobRZq0.png)

> Definition of POOLY
>
>   having many pools
>
> – Merriam-Webster Dictionary

_Pooly_ is a worker pool library inspired by other Erlang worker pool libraries such as [poolboy](https://github.com/devinus/poolboy), [pooler](https://github.com/seth/pooler) and [ppool](http://learnyousomeerlang.com/building-applications-with-otp) (from [Chapter 18](http://learnyousomeerlang.com/building-applications-with-otp) of _Learn You Some Erlang For Great Good_).

The whole point of this exercise is to make this project a part of the example project in Chapter 6 of the [book](http://www.exotpbook.com).

## API 

```elixir
alias Pooly, as: P

P.start_link
P.stop
```

### Starting a pool

This creates a named pool, attach it to the top-level supervisor and starts a bunch of workers.

### Worker Arguments

```elixir
pools_config =
  [
    [name: "Pool1",
      mfa: {SampleWorker, :start_link, []},
      size: 2,
      max_overflow: 10
    ],
    [name: "Pool2",
      mfa: {SampleWorker, :start_link, []},
      size: 2,
      max_overflow: 0
    ],
  ]


P.start_pool(pool_config)
```

### Stopping a pool

```elixir
P.stop_pool("Pool1")
```

### Getting workers

This is the most basic version:

```elixir
pid = P.checkout("Pool1")
```

`checkout/3` takes two other arguments. `block` (boolean) and `timeout`. The defaults are `true` and `5000` respectively. If `block` is true, the consumer process will wait for `timeout` milliseconds before timing out. Note that you can pass in `:infinity` as a timeout value.

For example, this consumer process will wait indefinitely for a process to be available:

```elixir
worker_pid = P.checkout("Pool1", true, :infinity)
```

### Return workers back to the pool

Returning workers is straightforward:

```elixir
P.checkin("Pool1", worker_pid) do
```

### Getting the status of a pool

```elixir
P.status("Pool1")
```

# Version 1

Although the first version is the most basic, it will get us a pretty long way, since it sets up the framework of the versions to come.

## Characteristics

* Supports a _single_ pool
* Supports a _fixed_ number of workers
* No queuing
* No recovery when consumer and/or worker process fail

## Details

When Pooly first starts (`Pooly.start_link`) it is just this:

```
              [Pooly.Supervisor]
                /
               /
        [Pooly.Server]
```

This is because there is no pool to be started yet. To do that:

```elixir
Pool.start_pool(:some_worker_pool, {SomeWorker, :start_link, []})
```

This creates a `Pooly.WorkerSupervisor` with a `:simple_one_for_one` strategy that essentially makes it a `SomeWorker` process factory. This is the _final_ state of the supervision tree, with no workers started yet.


```
              [Pooly.Supervisor]
                /            \
               /              \
        [Pooly.Server]    [Pooly.WorkerSupervisor]
```

Next, we need to work on limiting the number of workers. In order for this to happen, we need to introduce another variable. One option we _could_ do is:

```elixir
Pool.start_pool(:some_worker_pool, [5, {SomeWorker, :start_link, []]})
```

However, someone else taking a look at the code (that will be _you_, 2 weeks later) will be left wondering what exactly `5` does. A better way of expressing it would be using a _keyword list_:

```elixir
[
  mfa: {SomeWorker, :start_link, []},
  size: 5
]
```

With a size, we can create a fixed number of workers each time the supervisor starts. Put another way, the supervisor will create `size` number of workers.

### Checking out and in workers

The notion of checking in and out of workers is just like acquiring and releasing of a resource. In this case, the resource is the an available worker, represented by a process id.

To support this operation, we have the following functions:

```elixir
Pooly.checkout # returns an available worker pid, or :noproc if unavailable
```

When done, it the consumer of the worker pid (the process that did the previously check-out) must check the worker pid back in, otherwise, it will cause a resource starvation. An example could be a single process checking out every single worker, and not checking in back to the pool. We will fix this limitation later on. To check-in a worker:

```elixir
Pooly.checkin(:some_worker_pool, worker_pid)
```


### Server state

At the end of this iteration, the server state should look like:

```elixir
defmodule State do
   defstruct supervisor: nil,
             workers: [],
             monitors: :ets.new(:monitors, [:private]),
             size: 5
 end
```

### Running it

__TODO:__ _Create a sample worker and put `Pooly` through its paces_

# Version 2

## Characteristics

* Supports a _single_ pool
* Supports a _fixed_ number of workers
* No queuing
* recovery when consumer and/or worker process fail

### Linking

Besides checking in a worker, the worker could crash too. Othertimes, the worker could exit normally.  Since the supervisor stance on restarting crashed workers is `:temporary`, this means that workers are never restarted. That's because in general we never know whether a worker should be restarted. While you can build this into the implementation like having it as a setting, we will keep it simple. 

In order to handle these various situations, we need to know when something happens to a checked out worker process. Our worker processes should crash too if the server crashes. Links (and trapping exits) are perfect for this. What should happen when a worker crashes? Well, the pool should automatically create a new worker, no questions asked.

### Monitoring

How do we know when a consumer process dies? Monitors! What should happen then when we detect that a consumer process dies? How can we retrieve the worker? (Monitor reference!)

# Version 3

## Characteristics

* Supports _multiple_ pools by dynamically creating supervisors
* Supports a _variable_ number of workers

So far, our worker pool can only handle one pool, which isn't terribly useful. In this iteration, we will add support for multiple pools and finally add more bells and whistles (be specific about this).

### Supporting multiple queues

The most straight forward way would be to design the supervision tree like so:

```
               [Pooly.Supervisor]
                /      /  |   \
               /      /   |    \
        [Pooly.Server]    |     \
                    /     |      \
                   /      |  [Pooly.WorkerSupervisor]
     [Pooly.WorkerSupervisor]
                          |
                  [Pooly.WorkerSupervisor]
```

### Error Kernels and Error Isolation

We are essentially sticking more `WorkerSupervisor`'s into `Pooly.Supervisor`. This is a bad design. The issue here is the _error kernel_. Issues with any of the `WorkerSupervisor`s shouldn't affect the `Pooly.Server`. (More reasons needed, separation of concerns). It pays to think about what happens when a process crashes and who gets affected.


The fix is to add another supervisor to handle all the worker supervisors, say a `Pooly.WorkersSupervisor`. This _might_ design we are shooting for:

```
              [Pooly.Supervisor]
                /            \
               /              \
        [Pooly.Server]    [Pooly.WorkersSupervisor]
                            /         |         \
                           /          |   [Pooly.WorkerSupervisor]
        [Pooly.WorkerSupervisor]      |
                          [Pooly.WorkerSupervisor]
```

Do you notice another problem?

Currently, the poor `Pooly.Server` process has to handle every request that is meant for _any_ pool.

This means that the lone server process might pose a bottle neck if messages to it come fast and furious, and could potentially flood it's mailbox. `Pooly.Server` also presents a single point of failure, since it contains the state of _every_ pool, and having the server process dead renders the pools useless.

The simplest thing to do is to have a dedicated `Pool.Server` process for each pool. So let's stick `Pooly.Server` into `Pool.WorkersSupervisor` ok? Not ok! If we did that, then `WorkersSupervisor` is going to have to supervise `Pool.Server`s too.

> A good exercise would be to quickly sketch out how you think the supervision tree should look like.

```
              [Pooly.Supervisor]
                               \
                                \
                           [Pooly.PoolsSupervisor]
                            /         |         \
                           /          |         [*]
        [Pooly.PoolSupervisor]        |
            /             \          [*]
        [Pooly.Server]   [Pooly.WorkerSupervisor]
```

You might find it slightly weird (I do!) that the `Pooly.Supervisor` is only supervising one child. Why couldn't we let it supervise the `Pooly.PoolSupervisor`s instead? Well, we need something to take the place of `Pool.Server`. In particular, we need a process to start the pools! Now, starting the pool involves:

* Telling `PoolsSupervisor` to start a `Pooly.PoolSupervisor` child
* `Pooly.PoolSupervisor` will initialize a `Pooly.Server` and a `Pooly.WorkerSupervisor`.

In order words, this is how we want the design to look like:

```
              [Pooly.Supervisor]
                /              \
               /                \
[Pooly.PoolStarter]         [Pooly.PoolsSupervisor]
                            /         |         \
                           /          |         [*]
        [Pooly.PoolSupervisor]        |
            /             \          [*]
        [Pooly.Server]   [Pooly.WorkerSupervisor]
```

The `Pooly.PoolStarter` process is a simple GenServer that is stateless, since there is not need for it to keep any.


### Server state

```elixir
defmodule State do
  defstruct pool_sup: nil,
  worker_sup: nil,
  monitors: nil,
  monitors: nil,
  size: nil,
  workers: nil,
  name: nil,
  mfa: nil,
end
```

# Version 4

## Features

* Transactions
* Overflowing of workers
* Waiting and Queuing 

### Implementing automatic checkout/checkin with transactions

Up until now, it is the onus of the consumer process to check back in a worker process once it is done with it. However, this is an unreasonable requirement, and we can do better. Just like a database transaction, once the consumer process is done with it, we can automatically have the worker process checked back in. How do we do that?

### Blocking and Queuing

When all workers are busy, a consumer that is willing to wait will be queued up. In this implementation, that is the default behaviour. It is relatively straightforward to implement a non-blocking consumer. (Just have a parameter which says `block`, and if it says `false`, return something like `{:error, full}`)

For a consumer that blocks, once a worker is checked back into the pool, the consumer is then unblocked and given the worker.

### Supporting a variable number of workers

Next, we want to add some flexibility to `Pooly`. In particular, we want to specify a _maximum overflow_ of workers. What does this buy us? Consider the following scenario. (More research. See Sasa's [article](www.theerlangelist.com/2013/04/parallelizing-independent-tasks.html) on setting size to zero and overflow to 5, essentially for _dynamic_ workers)

### Server state

```elixir
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
```
