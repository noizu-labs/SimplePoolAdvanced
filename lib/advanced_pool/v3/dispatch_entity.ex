#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.DispatchEntity do
  @type t :: %__MODULE__{
               identifier: any,
               state: atom,
               server: atom, # elixir_node
               lock: nil | {{atom, pid}, atom, integer}
             }

  defstruct [
    identifier: nil,
    state: :spawning,
    server: nil, # elixir_node
    lock: nil
  ]
end
