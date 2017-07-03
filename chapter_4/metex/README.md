Metex
=====

`iex -S mix`


```elixir
iex> Metex.Worker.start_link

iex> Metex.Worker.get_temperature "Berlin"

iex> Meter.Worker.get_stats

iex> Meter.Worker.reset_stats

iex> Meter.Worker.get_stats

iex> Meter.Worker.stop
```
