#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.Status do
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :node
    public_field :status, :unknown
    public_field :state, :offline
    public_field :desired_state, :offline
    public_field :health_report
    public_field :updated_on
    public_field :state_changed_on
    public_field :desired_state_changed_on
  end

  def new(node) do
    %__MODULE__{
      node: node,
    }
  end

end
