# Concuerror Playground

1. Install [Concuerror](https://github.com/parapluu/Concuerror).
1. Make sure the tests all pass: `mix test`.
1. Here's an example command to run Concuerror on the `RegServer` module:

```
concuerror --pa /usr/local/Cellar/elixir/HEAD/lib/elixir/ebin/ \
           --pa /usr/local/Cellar/elixir/HEAD/lib/ex_unit/ebin \
           --pa _build/test/lib/concuerror_playground/ebin     \
           -m Elixir.RegServer.ConcurrencyTest \
           --graph concuerror.dot \
           --show_races true
```
