#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia

defdatabase Noizu.AdvancedPool.TestDatabase do

  #--------------------------------------
  # Dispatch
  #--------------------------------------
  deftable TestV3Pool.Dispatch.Table, [:identifier, :server, :entity], type: :set, index: [] do
    @type t :: %TestV3Pool.Dispatch.Table{identifier: tuple, server: atom, entity: Noizu.AdvancedPool.V3.DispatchEntity.t}
  end

  deftable TestV3TwoPool.Dispatch.Table, [:identifier, :server, :entity], type: :set, index: [] do
    @type t :: %TestV3TwoPool.Dispatch.Table{identifier: tuple, server: atom, entity: Noizu.AdvancedPool.V3.DispatchEntity.t}
  end

  deftable TestV3ThreePool.Dispatch.Table, [:identifier, :server, :entity], type: :set, index: [] do
    @type t :: %TestV3ThreePool.Dispatch.Table{identifier: tuple, server: atom, entity: Noizu.AdvancedPool.V3.DispatchEntity.t}
  end

end
