Code.require_file "../test_helper.exs", __DIR__

defmodule RegServer.ConcurrencyTest do
  use ExUnit.Case

  test "start stop" do
    assert :ok = RegServer.start
    assert :ok = RegServer.stop
  end

  test "ping" do
    RegServer.start
    assert :pong = RegServer.ping
    assert :pong = RegServer.ping
    RegServer.stop
  end

  test "multiple stops" do
    RegServer.start
    assert :ok = RegServer.stop
    assert :server_down = RegServer.stop
  end

  test "multiple concurrent stops" do
    RegServer.start
    me = self
    spawn(fn -> send(me, RegServer.stop) end)
    spawn(fn -> send(me, RegServer.stop) end)

    assert [:ok, :server_down] = receive_two
  end

  defp receive_two do
    receive do
      result_1 ->
        receive do
          result_2 ->
            [result_1, result_2] |> Enum.sort
        end
    end
  end

  # This is for Concuerror, which defaults to test/0
  # NOTE: run only one!
  def test do
    # apply(__MODULE__, :"test start stop", [""])
    # apply(__MODULE__, :"test ping", [""])
    # apply(__MODULE__, :"test multiple stops", [""])
    apply(__MODULE__, :"test multiple concurrent stops", [""])
  end

end
