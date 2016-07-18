defmodule ListEQC do
  use ExUnit.Case
  use EQC.ExUnit

  @tag numtests: 100
  property "Deleting from a list" do
    forall list <- ulist(int) do
      implies list != [] do
        forall item <- elements(list) do
          ensure not item in List.delete(list, item) == true
        end
      end
    end
  end

  property "Misconception of deleting from a list" do
    :eqc.fails(
      forall list <- list(int) do
        implies list != [] do
          forall item <- elements(list) do
            ensure not item in List.delete(list, item) == true
          end
        end
      end
    )
  end

  property "Deleting an element not in a list leaves the list unchanged" do
    forall list <- list(int) do
      forall item <- int do
        implies not item in list do
          ensure list == List.delete(list, item)
        end
      end
    end
  end

  property "sorting works" do
    forall l <- list(int) do
      ensure l |> Enum.sort |> is_sorted == true
    end 
  end


  # NOTE: Testing properties of reverse

  property "reverse is recursive" do
    forall l <- non_empty(list(char)) do
      equal Enum.reverse(l), Enum.reverse(tl(l)) ++ [hd(l)]
    end
  end

  property "reverse is distributive" do
    forall {l1, l2} <- {list(char), list(char)} do
      ensure Enum.reverse(l1 ++ l2) == Enum.reverse(l2) ++ Enum.reverse(l1)
    end
  end

  property "reverse is idempotent" do
    forall l <- list(char) do
      ensure l |> Enum.reverse |> Enum.reverse == l
    end
  end

  property "reverse is equivalent to the Erlang version" do
    forall l <- list(oneof [real, int]) do
      ensure Enum.reverse(l) == :lists.reverse(l)
    end
  end

  def is_sorted([]), do: true

  def is_sorted(list) do
    list 
    |> Enum.zip(tl(list)) 
    |> Enum.all?(fn {x, y} -> x <= y end)
  end

  def equal(x, y) do
    when_fail(IO.puts("FAILED ☛ #{inspect(x)} != #{inspect(y)}")) do
      x == y
    end
  end

  # Custom generator to generate unique lists
  def ulist(item) do
    let l <- list(item) do
      l |> Enum.sort |> Enum.uniq
    end
  end

end
