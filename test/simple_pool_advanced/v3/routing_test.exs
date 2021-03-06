#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.RoutingTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  require Logger

  @context Noizu.ElixirCore.CallingContext.system(%{})

  @tag :routing
  @tag :v2
  #@tag capture_log: true
  test "process across node" do
    ref = Noizu.AdvancedPool.TestHelpers.unique_ref_v2(:two)
    Noizu.AdvancedPool.Support.TestV3TwoPool.test_s_call!(ref, :bannana, @context)
    {:ack, pid} = Noizu.AdvancedPool.Support.TestV3TwoPool.Server.worker_management().process!(ref, @context, %{})
    assert is_pid(pid)
  end

  @tag :v2
  @tag capture_log: true
  test "process origin node" do
    ref = Noizu.AdvancedPool.TestHelpers.unique_ref_v2(:one)
    Noizu.AdvancedPool.Support.TestV3Pool.test_s_call!(ref, :bannana, @context)
    {:ack, pid} = Noizu.AdvancedPool.Support.TestV3Pool.Server.worker_management().process!(ref, @context, %{})
    assert is_pid(pid)
  end

end
