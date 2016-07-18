defmodule NumbersEQC do
  use ExUnit.Case
  use EQC.ExUnit
  
  property "the square of a real number is always positive" do
    forall x <- real do
      ensure x*x >= 0
    end
  end

  property "the square of the square root of a real number is the original number" do
    forall x <- pos_real do
      sq_root = :math.sqrt(x)
      ensure sq_root * sq_root - x < 0.000000000001
    end
  end

  def pos_real do
    let r <- real do
      :erlang.abs(r)
    end
  end
end
