#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.MonitoringFramework.Service.HealthCheck do
  @moduledoc """
  Service Health Check Status.
  """

  alias Noizu.AdvancedPool.MonitoringFramework.Service.Definition
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :identifier
    public_field :process
    public_field :time_stamp
    public_field :status, :offline
    public_field :directive, :locked
    public_field :definition
    public_field :allocated
    public_field :health_index, 0.0
    public_field :events, []
  end

  @doc """
    Return default template for HealthCheck
  """
  def template(pool, options \\ %{}) do
    server = options[:server] || node()
    %Noizu.AdvancedPool.MonitoringFramework.Service.HealthCheck{
      identifier: {server, pool},
      time_stamp: DateTime.utc_now(),
      status: :offline,
      directive: :init,
      definition: %Noizu.AdvancedPool.MonitoringFramework.Service.Definition{
        identifier: {server, pool},
        server: server,
        time_stamp: DateTime.utc_now(),
        pool: pool,
        service: Module.concat(pool, Server),
        supervisor: Module.concat(pool, PoolSupervisor),
        hard_limit: options[:hard_limit] || 250,
        soft_limit:  options[:soft_limit] || 150,
        target:  options[:target] || 100,
      },
    }
  end
end
