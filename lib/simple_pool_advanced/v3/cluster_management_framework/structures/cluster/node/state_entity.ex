#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Node.State do
  use Noizu.DomainObject
  @vsn 1.0
  @sref "node-state"
  @persistence_layer {Noizu.SimplePoolAdvanced.V3.Database, cascade_block?: true, table: Noizu.SimplePoolAdvanced.V3.Database.Cluster.Service.State.Table}
  defmodule Entity do
    Noizu.DomainObject.noizu_entity() do
      identifier :atom
      public_field :status
      public_field :state
      public_field :pending_state
      public_field :node_definition
      public_field :status_details
      public_field :servise_instances, %{}
      public_field :service_instances_statuses, %{}
      public_field :service_instances_health_reports, %{}
      public_field :health_report, :pending
      public_field :updated_on
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
