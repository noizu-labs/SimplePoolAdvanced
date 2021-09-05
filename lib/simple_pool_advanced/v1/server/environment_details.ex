#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SimplePoolAdvanced.Server.EnvironmentDetails do
  @type t :: %__MODULE__{
               server: any,
               definition: any,
               initial: Noizu.SimplePoolAdvanced.MonitoringFramework.Service.HealthCheck.t,
               effective: Noizu.SimplePoolAdvanced.MonitoringFramework.Service.HealthCheck.t,
               default: any,
               status: atom,
               monitors: Map.t,
             }

  defstruct [
    server: nil,
    definition: nil,
    initial: nil,
    effective: nil,
    default: nil,
    status: nil,
    monitors: %{}
  ]

end