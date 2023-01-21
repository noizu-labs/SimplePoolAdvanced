#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.Server.State do
  alias Noizu.AdvancedPool.V3.Server.State

  @vsn 1.0
  use Noizu.SimpleObject
  Noizu.SimpleObject.noizu_struct() do
    public_field :worker_supervisor
    public_field :service
    public_field :pool
    public_field :status_details
    public_field :status,  %{loading: :pending, state: :pending}
    public_field :extended, %{}
    public_field :entity
    public_field :environment_details
    public_field :options
  end

end
