#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.MessageProcessingBehaviour do
  require Logger

  # call routing
  @callback __handle_call__(any, any, any) :: any

  # cast routing
  @callback __handle_cast__(any, any) :: any

  # info routing
  @callback __handle_info__(any, any) :: any

  @callback as_cast(tuple) :: tuple
  @callback as_info(tuple) :: tuple
end
