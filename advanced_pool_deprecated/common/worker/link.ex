#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule  Noizu.AdvancedPool.Worker.Link do
  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :ref
    public_field :handler
    public_field :handle
    public_field :expire, 0
    public_field :update_after, 300
    public_field :state, :unknown
  end
end
