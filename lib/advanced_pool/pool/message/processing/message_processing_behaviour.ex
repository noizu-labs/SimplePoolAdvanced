#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.MessageProcessingBehaviour do
  require Logger

  # call routing
  @callback call_router_user(any, any, any) :: any
  @callback call_router_internal(any, any, any) :: any
  @callback call_router_catchall(any, any, any) :: any
  @callback __call_handler(any, any, any) :: any

  # cast routing
  @callback cast_router_user(any, any) :: any
  @callback cast_router_internal(any, any) :: any
  @callback cast_router_catchall(any, any) :: any
  @callback __cast_handler(any, any) :: any

  # info routing
  @callback info_router_user(any, any) :: any
  @callback info_router_internal(any, any) :: any
  @callback info_router_catchall(any, any) :: any
  @callback __info_handler(any, any) :: any

  @callback as_cast(tuple) :: tuple
  @callback as_info(tuple) :: tuple
end
