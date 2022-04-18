#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.Definition do
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :service
    public_field :worker_window, %{low: nil, high: nil, target: nil}
    public_field :node_window, %{low: nil, high: nil, target: nil}
    public_field :monitors, %{}
    public_field :telemetrics, %{}
  end

  def new(service, worker_window, node_window) do
    %__MODULE__{
      service: service,
      worker_window: worker_window,
      node_window: node_window,
    }
  end
end
