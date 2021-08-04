#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia

defdatabase Noizu.SimplePool.TestDatabase do

  #--------------------------------------
  # Dispatch
  #--------------------------------------
  deftable TestV3Pool.DispatchTable, [:identifier, :server, :entity], type: :set, index: [] do
    @type t :: %TestV3Pool.DispatchTable{identifier: tuple, server: atom, entity: Noizu.SimplePool.V3.DispatchEntity.t}
  end

  deftable TestV3TwoPool.DispatchTable, [:identifier, :server, :entity], type: :set, index: [] do
    @type t :: %TestV3TwoPool.DispatchTable{identifier: tuple, server: atom, entity: Noizu.SimplePool.V3.DispatchEntity.t}
  end

  deftable TestV3ThreePool.DispatchTable, [:identifier, :server, :entity], type: :set, index: [] do
    @type t :: %TestV3ThreePool.DispatchTable{identifier: tuple, server: atom, entity: Noizu.SimplePool.V3.DispatchEntity.t}
  end

end
