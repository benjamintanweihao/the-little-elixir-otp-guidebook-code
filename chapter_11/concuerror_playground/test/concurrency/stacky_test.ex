Code.require_file "../test_helper.exs", __DIR__

defmodule Stacky.ConcurrencyTest do
  
  def test do
    {:ok, _pid} = Stacky.start_link
    Stacky.tag(1)
    Stacky.stop
    :ok
  end

end


