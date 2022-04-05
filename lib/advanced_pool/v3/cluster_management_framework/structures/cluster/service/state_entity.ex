#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State do
  use Noizu.DomainObject
  @vsn 1.0
  @sref "service-state"
  @persistence_layer {Noizu.AdvancedPool.V3.Database, cascade_block?: true, table: Noizu.AdvancedPool.V3.Database.Cluster.Service.State.Table}
  defmodule Entity do
    Noizu.DomainObject.noizu_entity() do
      identifier :atom
      public_field :status, :unknown
      public_field :state, :offline
      public_field :pending_state, :offline
      public_field :service_definition
      public_field :status_details
      public_field :instance_definitions, %{}
      public_field :instance_statuses, %{}
      public_field :health_report, :pending
      public_field :updated_on
      public_field :telemetry_handler
      public_field :event_handler
      public_field :state_changed_on
      public_field :pending_state_changed_on

    end

    def reset(%__MODULE__{} = this, _context, options \\ %{}) do
      current_time = options[:current_time] || DateTime.utc_now()
      # @TODO flag service status entries as unknown/pending to force status updates.
      %__MODULE__{this|
        status: :warmup,
        state: :init,
        pending_state: :online,
        state_changed_on: current_time,
        pending_state_changed_on: current_time
      }
    end

  end



  defmodule Repo do
    Noizu.DomainObject.noizu_repo() do

    end
  end



end
