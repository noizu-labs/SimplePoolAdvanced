#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.MonitoringFramework.Service.Definition do
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :identifier
    public_field :server
    public_field :pool
    public_field :service
    public_field :supervisor
    public_field :server_options
    public_field :worker_sup_options
    public_field :time_stamp
    public_field :hard_limit, 0
    public_field :soft_limit, 0
    public_field :target, 0
  end
end
