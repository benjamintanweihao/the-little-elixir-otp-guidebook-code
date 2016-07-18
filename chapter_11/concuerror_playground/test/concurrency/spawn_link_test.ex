Code.require_file "../test_helper.exs", __DIR__

defmodule SpawnLink.ConcurrencyTest do
  
  def test do
    # This will call a crash!
    Process.link(spawn(fn -> 
      :timer.sleep(5000) 
    end))

    # This will not!
    # spawn_link(fn -> 
    #   :timer.sleep(5000) 
    # end)

  end

end
