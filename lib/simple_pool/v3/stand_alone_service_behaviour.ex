#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SimplePool.V3.StandAloneServiceBehaviour do
  defmacro __using__(options) do
      quote do
        use Noizu.SimplePool.V2.StandAloneServiceBehaviour, unquote(options)
      end
  end
end
