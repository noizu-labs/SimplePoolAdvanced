#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.RouterBehaviour do

  @callback options() :: any
  @callback option(any, any) :: any

  @callback extended_call(any, any, any, any, any, any) :: any

  @callback self_call(any, any, any) :: any
  @callback self_cast(any, any, any) :: any

  @callback internal_system_call(any, any, any) :: any
  @callback internal_system_cast(any, any, any) :: any

  @callback internal_call(any, any, any) :: any
  @callback internal_cast(any, any, any) :: any

  @callback remote_system_call(any, any, any, any) :: any
  @callback remote_system_cast(any, any, any, any) :: any

  @callback remote_call(any, any, any, any) :: any
  @callback remote_cast(any, any, any, any) :: any

  @callback get_direct_link!(any, any, any) :: any

  @callback s_call_unsafe(any, any, any, any, any) :: any
  @callback s_cast_unsafe(any, any, any, any) :: any

  @callback s_call!(any, any, any, any) :: any
  @callback rs_call!(any, any, any, any) :: any

  @callback s_call(any, any, any, any) :: any
  @callback rs_call(any, any, any, any) :: any

  @callback s_cast!(any, any, any, any) :: any
  @callback rs_cast!(any, any, any, any) :: any

  @callback s_cast(any, any, any, any) :: any
  @callback rs_cast(any, any, any, any) :: any


  @callback link_forward!(any, any, any, any) :: any

  @callback run_on_host(any, any, any, any, any) :: any
  @callback cast_to_host(any, any, any, any) :: any

end
