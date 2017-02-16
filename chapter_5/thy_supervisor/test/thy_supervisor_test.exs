defmodule ThySupervisorTest do
  use ExUnit.Case

  test "can be initialized given child specs" do
    assert {:ok, _} = ThySupervisor.start_link(child_spec_list)
  end

  test "a child can be started" do
    {:ok, sup_pid} = ThySupervisor.start_link(child_spec_list)
    {:ok, _child_pid} = ThySupervisor.start_child(sup_pid, {ThyWorker, :start_link, []})
    assert 4 == ThySupervisor.count_children(sup_pid)
  end

  test "a child can be terminated" do
    {:ok, sup_pid}   = ThySupervisor.start_link([])
    {:ok, child_pid} = ThySupervisor.start_child(sup_pid, {ThyWorker, :start_link, []})

    assert :ok  == ThySupervisor.terminate_child(sup_pid, child_pid)
    assert Process.alive?(sup_pid)
    assert 0    == ThySupervisor.count_children(sup_pid)
  end

  test "restarts an abnormally terminated child" do
    {:ok, sup_pid}   = ThySupervisor.start_link([])
    {:ok, child_pid} = ThySupervisor.start_child(sup_pid, {ThyWorker, :start_link, []})

    Process.exit(child_pid, :crash)
    refute Process.alive?(child_pid)

    new_child_pid = ThySupervisor.which_children(sup_pid) |> Map.keys |> List.first

    assert 1 == ThySupervisor.count_children(sup_pid)
    assert is_pid(new_child_pid)
    assert new_child_pid != child_pid
  end

  defp child_spec_list do
    [
      {ThyWorker, :start_link, []},
      {ThyWorker, :start_link, []},
      {ThyWorker, :start_link, []},
    ]
  end
end
