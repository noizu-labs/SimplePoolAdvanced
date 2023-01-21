#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.Definition do
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :node
    public_field :worker_window, %{low: nil, high: nil, target: nil}
    public_field :ram_window, %{low: nil, high: nil, target: nil}
    public_field :cpu_window, %{low: nil, high: nil, target: nil}
    public_field :disk_window, %{low: nil, high: nil, target: nil}
    public_field :weight, 1.0
    public_field :monitors, %{}
    public_field :telemetrics, %{}
  end

  def new(node, worker_window, ram_window, cpu_window, disk_window, weight) do
    %__MODULE__{
      node: node,
      worker_window: worker_window,
      ram_window: ram_window,
      cpu_window: cpu_window,
      disk_window: disk_window,
      weight: weight
    }
  end
end
