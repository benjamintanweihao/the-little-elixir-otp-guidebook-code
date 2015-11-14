# Chucky - A Distributed and Fault-Tolerant Chuck Norris Facts Disher

![Chuck](http://i.imgur.com/wwFsWiA.jpg)

## Step 1: Figure out your hostname

```
% hostname -s
imac
```

## Step 2: Configure `config/NODE_NAME.config`

Here's an example:

```elixir
[{kernel,
  [{distributed, 
    [{chucky,
      5000,
      ['a@imac', {'b@imac', 'c@imac'}]}]},
   {sync_nodes_mandatory, ['b@imac', 'c@imac']},
   {sync_nodes_timeout, 30000}
  ]}].
```

## Step 3: Compile


```
% mix compile
```

## Step 4: Run it!

Open 3 different terminals, and on each of them, run these commands:

```
% iex --sname a -pa _build/dev/lib/chucky/ebin --app chucky --erl "-config config/a.config"

% iex --sname b -pa _build/dev/lib/chucky/ebin --app chucky --erl "-config config/b.config"

% iex --sname c -pa _build/dev/lib/chucky/ebin --app chucky --erl "-config config/c.config"
```

In each terminal, run:

```elixir
iex > Chucky.fact
"In a fight between Batman and Darth Vader, the winner would be Chuck Norris."
```

You can also use `Application.started_applications/1` to see where the application is being run on.

## Step 5: Watching failover in action

Kill the first session (`a@HOSTNAME`), then watch `b@HOSTNAME` get started:

```
07:33:04.831 [info]  b@manticore starting distributed

07:33:12.025 [info]  Application chucky exited: :stopped

07:33:42.300 [info]  b@manticore starting distributed
```

## Step 6: Watching takeover in action

Start `a@HOSTNAME` again:

```
% iex --sname a -pa _build/dev/lib/chucky/ebin --app chucky --erl "-config config/a.config"
```

Watch `a@HOSTNAME` take over `b@HOSTNAME`:

```
07:39:49.820 [info]  a@manticore is taking over b@manticore
```

