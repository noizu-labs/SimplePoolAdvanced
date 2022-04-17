#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.V3.ClusterManagement.HealthReport.Check do
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :name
    public_field :provider
    public_field :summary, :pending
    public_field :details
    public_field :updated_on
  end
end
