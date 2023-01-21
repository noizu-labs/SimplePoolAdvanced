#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.MonitoringFramework.LifeCycleEvent do
  @vsn 1.0
  use Noizu.SimpleObject

  Noizu.SimpleObject.noizu_struct() do
    public_field :identifier
    public_field :time_stamp
    public_field :details
  end
end
