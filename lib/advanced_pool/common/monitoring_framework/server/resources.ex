#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.MonitoringFramework.Server.Resources do
  @moduledoc """
  Track Node Server Resources.
  """

  @vsn 1.0
  use Noizu.SimpleObject

  Noizu.SimpleObject.noizu_struct() do
    public_field :identifier
    public_field :time_stamp
    public_field :cpu, %{nproc: 0, load: %{1 => 0.0, 5 => 0.0, 15 => 0.0, 30 => 0.0}}
    public_field :ram, %{total: 0.0, allocated: 0.0}
  end
end
