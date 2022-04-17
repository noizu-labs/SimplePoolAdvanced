#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.Instance.Status do
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :service
    public_field :node
    public_field :service_monitor
    public_field :service_process
    public_field :service_error
    public_field :status, :unknown
    public_field :state, :offline
    public_field :pending_state, :offline
    public_field :health_report
    public_field :updated_on
    public_field :state_changed_on
    public_field :pending_state_changed_on
  end

  def new(service, node, pool_supervisor_pid, error) do
    %__MODULE__{
      service: service,
      node: node,
      service_monitor: pool_supervisor_pid && Process.monitor(pool_supervisor_pid),
      service_process: pool_supervisor_pid,
      service_error: error,
      updated_on: DateTime.utc_now(),
      state_changed_on: DateTime.utc_now(),
      pending_state_changed_on: DateTime.utc_now(),
    }
  end

end
