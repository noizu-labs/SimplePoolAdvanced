#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.Worker.State do
  alias Noizu.AdvancedPool.Worker.State

  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :initialized, false
    public_field :migrating, false
    public_field :worker_ref
    public_field :inner_state
    public_field :last_activity
    public_field :extended, %{}
  end
end
