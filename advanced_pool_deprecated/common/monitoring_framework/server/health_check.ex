#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.MonitoringFramework.Server.HealthCheck do
  @moduledoc """
    Track the Health Status of a Server Node.
  """
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :identifier
    public_field :master_node
    public_field :time_stamp
    public_field :status, :offline
    public_field :directive, :locked
    public_field :services
    public_field :resources
    public_field :events, []
    public_field :health_index, 0
    public_field :entry_point
  end

end
