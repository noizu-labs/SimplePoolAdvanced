#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.IUnitTests.StubTest do
  use ExUnit.Case
  require Logger

  def context(), do: Noizu.ElixirCore.CallingContext.system()

  test "hello world" do
    IO.puts "HELLO"
    Process.sleep(5_000)
  end

end
