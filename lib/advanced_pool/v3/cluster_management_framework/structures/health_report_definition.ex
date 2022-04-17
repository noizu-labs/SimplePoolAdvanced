#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.V3.ClusterManagement.HealthReportDefinition do
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :subject
    public_field :checks, %{}
    public_field :updated_on
  end

  def new(subject) do
    %__MODULE__{
      subject: subject
    }
  end

end
