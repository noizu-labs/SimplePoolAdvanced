#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SimplePoolAdvanced.V3.Support.TopologyProvider do
  @behaviour Noizu.MnesiaVersioning.TopologyBehaviour

  def mnesia_nodes() do
    {:ok, [node()]}
  end

  def database() do
    [Noizu.SimplePoolAdvanced.V3.Database]
  end
end
