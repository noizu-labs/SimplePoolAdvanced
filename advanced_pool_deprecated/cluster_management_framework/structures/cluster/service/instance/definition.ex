#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.Instance.Definition do
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :service
    public_field :node
    public_field :launch_parameters, :auto
    public_field :worker_window, %{low: nil, high: nil, target: nil}
    public_field :weight, 1.0
    public_field :monitors, %{}
    public_field :telemetrics, %{}
  end

  def new(service, node, worker_window, weight) do
    %__MODULE__{
      service: service,
      node: node,
      worker_window: worker_window,
      weight: weight
    }
  end
end
