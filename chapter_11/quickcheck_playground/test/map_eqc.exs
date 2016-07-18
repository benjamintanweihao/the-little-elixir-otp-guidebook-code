defmodule MapEQC do
  use ExUnit.Case
  use EQC.ExUnit

  # NOTE: Strange that this should fail but doesn't.
  property "keys are unique (take 1)" do
    forall m <- map_1 do
      no_duplicates(Map.keys(m))
    end
  end

  property "keys are unique (take 2)" do
    forall m <- map_2 do
      no_duplicates(Map.keys(:eqc_symbolic.eval(m)))
    end
  end

  property "storing keys and values" do
    forall {k, v, m} <- {key, val, map_2} do
      map = :eqc_symbolic.eval(m)
      lists_equal(model(Map.put(map, k, v)), model_store(k, v, model(map)))
    end
  end

  property "merging maps is *not* commutative" do
    forall {m1, m2} <- {map_2, map_2} do
      map_1 = :eqc_symbolic.eval(m1)
      map_2 = :eqc_symbolic.eval(m2)

      # NOTE: This will not work, since keys can be overriden! 
      #       Cool that QC finds this out after ~ 79 tests
      :eqc.fails(
        ensure Map.merge(map_1, map_2) == Map.merge(map_2, map_1)
      )
    end
  end

  property "merging maps retains keys" do
    forall {m1, m2} <- {map_2, map_2} do
      map_1 = :eqc_symbolic.eval(m1)
      map_2 = :eqc_symbolic.eval(m2)

      left_keys  = Map.merge(map_1, map_2) |> Map.keys
      right_keys = Map.merge(map_2, map_1) |> Map.keys
        
      equal(left_keys, right_keys)
    end
  end

  # First version of map generator
  # NOTE: there's a recursive call to map_1(). We need to
  #       use the `lazy` macro here.
  def map_1 do
    map_gen = lazy do
      let {k, v, m} <- {key, val, map_1} do
        Map.put(m, k, v)
      end
    end

    oneof [Map.new, map_gen]
  end

  # NOTE: Make sure that the order is right!
  # {:call, Map, :put, [key, val, map_2]}] will *not* work!
  def map_2 do
    lazy do
      oneof [{:call, Map, :new, []},
             {:call, Map, :put, [map_2, key, val]}]
    end
  end

  def no_duplicates(elems) do
    left  = elems |> Enum.sort
    right = elems |> Enum.uniq |> Enum.sort
    # equal(:lists.sort(elems), :lists.usort(elems))
    equal(left, right)
  end

  def key do
    oneof [int, real, atom]
  end

  def val do
    key
  end

  def atom do
    elements [:a, :b, :c, true, false, :ok]
  end

  def model(map) do
    Map.to_list(map) 
  end

  def model_store(k, v, list) do
    case find_index_with_key(k, list) do
      {:match, index} ->
        List.replace_at(list, index, {k, v})
      _ ->
        [{k, v} | list]
    end
  end

  def find_index_with_key(k, list) do
    case Enum.find_index(list, fn({x,_}) -> x == k end) do
      nil   -> :nomatch
      index -> {:match, index}
    end
  end

  def equal(x, y) do
    when_fail(IO.puts("FAILED ☛ #{inspect(x)} != #{inspect(y)}")) do
      x == y
    end
  end

  def lists_equal(x, y) do
    equal(Enum.sort(x), Enum.sort(y))
  end

end
