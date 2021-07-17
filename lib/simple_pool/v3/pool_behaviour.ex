#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SimplePool.V3.PoolBehaviour do
  defmacro __using__(options) do
      quote do
        use Noizu.SimplePool.V2.PoolBehaviour, unquote(options)
      end
  end
end
