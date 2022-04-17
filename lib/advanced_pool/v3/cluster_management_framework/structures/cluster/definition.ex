#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Definition do
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :cluster
    public_field :monitors, %{}
    public_field :telemetrics, %{}
  end

  def new(cluster) do
    %__MODULE__{
      cluster: cluster,
    }
  end
end
