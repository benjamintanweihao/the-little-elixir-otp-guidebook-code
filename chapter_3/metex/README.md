Metex
=====

A simple Elixir app that reports the temperature given a location.

## Running Metex 

```elixir
iex> cities = ["Singapore", "Monaco", "Vatican City", "Hong Kong", "Macau"]

iex> Metex.temperatures_of(cities)
Hong Kong: 17.8°C, Macau: 18.4°C, Monaco: 8.8°C, Singapore: 28.6°C, Vatican City: 8.5°C
```

