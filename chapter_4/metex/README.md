Metex
=====

`iex -S mix`


```elixir
iex> Metex.Worker.start_link

iex> Metex.Worker.get_temperature "Berlin"

iex> Metex.Worker.get_stats

iex> Metex.Worker.reset_stats

iex> Metex.Worker.get_stats

iex> Metex.Worker.stop
```
