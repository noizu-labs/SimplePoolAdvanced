#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.RoutingTest do
  use ExUnit.Case
  require Logger

  def context(), do: Noizu.ElixirCore.CallingContext.system()

  @tag :routing
  @tag :v2
  #@tag capture_log: true
  test "process across node" do
    Noizu.AdvancedPool.Support.TestManager.bring_all_online(context())
    {_, host, _} = Noizu.AdvancedPool.Support.TestPool.fetch(321, :process, context())
    assert host == node()
    {_, host, _} = Noizu.AdvancedPool.Support.TestPool3.fetch(321, :process, context())
    assert host != node()
  end

  @tag :v2
  @tag capture_log: true
  test "process origin node" do
    Noizu.AdvancedPool.NodeManager.bring_online(node(), context()) |> Task.yield()
    Noizu.AdvancedPool.NodeManager.bring_online(:"second@127.0.0.1", context()) |> Task.yield()
    {_, host, _} = Noizu.AdvancedPool.Support.TestPool3.fetch(123, :process, context())
    assert host != node()
  end

end
