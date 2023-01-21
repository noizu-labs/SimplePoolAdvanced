#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State do
  use Noizu.DomainObject
  @vsn 1.0
  @sref "cluster-state"
  @persistence_layer {Noizu.AdvancedPool.V3.Database, cascade_block?: true, table: Noizu.AdvancedPool.V3.Database.Cluster.State.Table}
  defmodule Entity do
    Noizu.DomainObject.noizu_entity() do
      identifier :atom
      public_field :node
      public_field :process
      public_field :status, :unkown
      public_field :state, :offline
      public_field :pending_state
      public_field :cluster_definition
      public_field :service_definitions, %{}
      public_field :service_statuses, %{}
      public_field :status_details, %{}
      public_field :health_report, :pending
      public_field :updated_on
      public_field :telemetry_handler
      public_field :event_handler
      public_field :state_changed_on
      public_field :pending_state_changed_on
    end

    def reset(%__MODULE__{} = this, _context, options \\ %{}) do
      # Todo flag statuses as pending
      current_time = options[:current_time] || DateTime.utc_now()
      %__MODULE__{this|
        node: options[:node] || node(),
        process: options[:pid] || self(),
        status: :warmup,
        state: :init,
        pending_state: :online,
        state_changed_on: current_time,
        pending_state_changed_on: current_time,
        #state_changed_on: DateTime.utc_now(),
        #pending_state_changed_on: DateTime.utc_now()
      }
    end


  end

  defmodule Repo do
    Noizu.DomainObject.noizu_repo() do

    end
  end




end
