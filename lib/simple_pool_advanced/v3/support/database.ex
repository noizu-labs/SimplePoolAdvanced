#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia

defdatabase Noizu.SimplePoolAdvanced.V3.Database do
  def database(), do: __MODULE__

  #=======================================================
  # Cluster Management Tables
  #=======================================================
  deftable Cluster.Setting.Table, [:setting, :value], type: :bag, index: [] do
    @type t :: %Cluster.Setting.Table{setting: atom, value: any}
  end


  #-----------------------------
  # Cluster Manager
  #-----------------------------
  deftable Cluster.State.Table, [:identifier, :entity], type: :set, index: [] do
    @moduledoc """
      Cluster Wide Configuration
    """
    @type t :: %Cluster.State.Table{identifier: any, entity: any}
  end

  deftable Cluster.Task.Table, [:identifier, :entity], type: :set, index: [] do
    @moduledoc """
      Pending Tasks Scheduled or Pending Approval (Rebalance Cluster, Shutdown Node, Select new Service Manager etc.)
    """
    @type t :: %Cluster.Task.Table{identifier: any, entity: any}
  end


  #-----------------------------
  # Service Manager
  #-----------------------------
  deftable Cluster.Service.State.Table, [:identifier, :entity], type: :set, index: [] do
    @moduledoc """
      Service State Snapshot, Active Manger Node, etc.
    """
    @type t :: %Cluster.Service.State.Table{identifier: any, entity: any}
  end

  deftable Cluster.Service.Worker.Table, [:identifier, :entity], type: :set, index: [] do
    @moduledoc """
      Service State Snapshot, Active Manger Node, etc.
    """
    @type t :: %Cluster.Service.Worker.Table{identifier: any, entity: any}
  end

  deftable Cluster.Service.Task.Table, [:identifier, :entity], type: :set, index: [] do
    @moduledoc """
      Pending Tasks Scheduled or Pending Approval.
    """
    @type t :: %Cluster.Service.Task.Table{identifier: any, entity: any}
  end

  deftable Cluster.Service.Instance.State.Table, [:identifier, :entity], type: :set, index: [] do
    @moduledoc """
      Per-Node Service State Snapshot
    """
    @type t :: %Cluster.Service.Instance.State.Table{identifier: any, entity: any}
  end

  #-----------------------------
  # Node Manager
  #-----------------------------
  deftable Cluster.Node.State.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %Cluster.Node.State.Table{identifier: any, entity: any}
  end

  deftable Cluster.Node.Worker.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %Cluster.Node.Worker.Table{identifier: any, entity: any}
  end

  deftable Cluster.Node.Task.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %Cluster.Node.Task.Table{identifier: any, entity: any}
  end







  #====================================================================
  # Deprecated
  #====================================================================


  #--------------------------------------
  # Monitoring Framework
  #--------------------------------------
  deftable MonitoringFramework.Setting.Table, [:setting, :value], type: :bag, index: [] do
    @type t :: %MonitoringFramework.Setting.Table{setting: atom, value: any}
  end

  deftable MonitoringFramework.Configuration.Table, [:identifier, :entity], type: :set, index: [] do
    @type t :: %MonitoringFramework.Configuration.Table{identifier: any, entity: any}
  end

  deftable MonitoringFramework.Node.Table, [:identifier, :status, :directive, :health_index, :entity], type: :set, index: [] do
    @type t :: %MonitoringFramework.Node.Table{identifier: any, status: atom, directive: atom,  health_index: float, entity: any}
  end

  deftable MonitoringFramework.Service.Table, [:identifier, :status, :directive, :health_index, :entity], type: :set, index: [] do
    @type t :: %MonitoringFramework.Service.Table{identifier: {atom, atom}, status: atom, directive: atom,  health_index: float, entity: any}
  end

  deftable MonitoringFramework.DetailedServiceEvent.Table, [:identifier, :event, :time_stamp, :entity], local: true, type: :bag, index: [] do
    @type t :: %MonitoringFramework.DetailedServiceEvent.Table{identifier: {atom, atom}, event: atom, time_stamp: integer, entity: any}
  end

  deftable MonitoringFramework.ServiceEvent.Table, [:identifier, :event, :time_stamp, :entity], type: :bag, index: [] do
    @type t :: %MonitoringFramework.ServiceEvent.Table{identifier: {atom, atom}, event: atom, time_stamp: integer, entity: any}
  end

  deftable MonitoringFramework.ServerEvent.Table, [:identifier, :event, :time_stamp, :entity], type: :bag, index: [] do
    @type t :: %MonitoringFramework.ServerEvent.Table{identifier: atom, event: atom, time_stamp: integer, entity: any}
  end

  deftable MonitoringFramework.DetailedServerEvent.Table, [:identifier, :event, :time_stamp, :entity], type: :bag, local: true, index: [] do
    @type t :: %MonitoringFramework.DetailedServerEvent.Table{identifier: atom, event: atom, time_stamp: integer, entity: any}
  end

  deftable MonitoringFramework.ClusterEvent.Table, [:identifier, :event, :time_stamp, :entity], type: :bag, index: [] do
    @type t :: %MonitoringFramework.ClusterEvent.Table{identifier: atom, event: atom, time_stamp: integer, entity: any}
  end

end
