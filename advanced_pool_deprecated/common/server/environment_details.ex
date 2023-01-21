#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.Server.EnvironmentDetails do
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :server
    public_field :definition
    public_field :initial
    public_field :effective
    public_field :default
    public_field :status
    public_field :monitors, %{}
  end
end
