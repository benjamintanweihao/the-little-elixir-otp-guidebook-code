Blitzy - A simple HTTP load tester in Elixir
============================================

![](http://i.imgur.com/Z8zyXZu.gif)

Inspired by this [post](http://www.watchsumo.com/posts/introduction-to-elixir-v1-0-0-by-example-i) by Victor Martinez of WatchSumo.

```
% ./blitzy -n 100 http://www.bieberfever.com
```

## Distributed Blitzy

It is _way_ more fun to start distributed. Edit the provided `config/config.exs` with whatever node name suits your fancy. This is optional, and you can stick to the provided one.

```elixir
config :blitz, master_node: :"a@127.0.0.1"

config :blitz, slave_nodes: [:"b@127.0.0.1", 
                             :"c@127.0.0.1",
                             :"d@127.0.0.1"] 
```

Here, the master node is `:a@127.0.0.1`; the rest are slave nodes.

Start up a couple of nodes, and name them accordingly. For example, here's how to start one of them:

```
% iex --name b@127.0.0.1 -S mix
```

Now, when you run the the command

```
% ./blitzy -n 100 http://www.bieberfever.com
```

the requests will be split across the number of nodes you created, including the master node. Here's an example run:

```
17:03:30.600 [info]  worker [a@127.0.0.1-256] completed in 5451.854 msecs

17:03:30.600 [info]  worker [b@127.0.0.1-289] completed in 5258.639999999999 msecs

17:03:30.600 [info]  worker [b@127.0.0.1-278] completed in 5272.281 msecs

17:03:30.600 [info]  worker [a@127.0.0.1-310] completed in 5452.012 msecs

17:03:30.600 [info]  worker [b@127.0.0.1-290] completed in 5258.318 msecs

17:03:30.600 [info]  worker [b@127.0.0.1-237] completed in 5300.413 msecs
...
17:03:31.023 [info]  worker [a@127.0.0.1-322] completed in 5653.303 msecs
  Succeeded         : 50
  Failures          : 0
  Total time (msecs): 542665.9879999999
  Avg time   (msecs): 1629.6275915915912


17:03:31.024 [info]  worker [c@127.0.0.1-22] completed in 5609.749 msecs
  Succeeded         : 50 
  Failures          : 0
  Total time (msecs): 485414.8010000001
  Avg time   (msecs): 1457.7021051051054
```

## Building the Executable

```
mix escript.build
```


