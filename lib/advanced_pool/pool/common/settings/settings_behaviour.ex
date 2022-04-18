#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.SettingsBehaviour do
  @moduledoc """
    The Noizu.AdvancedPool.V3.Behaviour provides the entry point for Worker Pools.
    The developer will define a pool such as ChatRoomPool that uses the Noizu.AdvancedPool.V3.Behaviour Implementation
    before going on to define worker and server implementations.

    The module is relatively straight forward, it provides methods to get pool information (pool worker, pool supervisor)
    compile options, runtime settings (via the FastGlobal library and our meta function).
  """

  # @deprecated
  @callback base() :: module

  @callback pool() :: module
  @callback pool_worker_supervisor() :: module
  @callback pool_server() :: module
  @callback pool_supervisor() :: module
  @callback pool_worker() :: module
  @callback pool_monitor() :: module

  @callback banner(String.t) :: String.t
  @callback banner(String.t, String.t) :: String.t

  @callback verbose() :: Map.t

  @callback pool_worker_state_entity() :: module

  @callback meta() :: Map.t
  @callback meta(Map.t) :: Map.t
  @callback meta_init() :: Map.t

  @callback options() :: Map.t
  @callback option_settings() :: Map.t

end
