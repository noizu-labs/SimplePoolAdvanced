#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.Support.TestV3Pool do
  #alias Noizu.Scaffolding.CallingContext
  use Noizu.AdvancedPool.V3.PoolBehaviour,
      default_modules: [:pool_supervisor, :worker_supervisor, :monitor],
      worker_state_entity: Noizu.AdvancedPool.Support.TestV3WorkerEntity,
      dispatch_table: Noizu.AdvancedPool.TestDatabase.TestV3Pool.Dispatch.Table,
      verbose: false

  defmodule Worker do
    @vsn 1.0
    use Noizu.AdvancedPool.V3.WorkerBehaviour,
        worker_state_entity: Noizu.AdvancedPool.Support.TestV3WorkerEntity,
        verbose: false
    require Logger
  end # end worker

  #=============================================================================
  # @Server
  #=============================================================================
  defmodule Server do
    @vsn 1.0
    use Noizu.AdvancedPool.V3.ServerBehaviour,
        worker_state_entity: Noizu.AdvancedPool.Support.TestV3WorkerEntity,
        worker_lookup_handler: Noizu.AdvancedPool.WorkerLookupBehaviour.Dynamic
  end # end defmodule GoldenRatio.Components.Gateway.Server


  #---------------------------------------------------------------------------
  # Convenience Methods
  #---------------------------------------------------------------------------
  def test_s_call!(identifier, value, context) do
    __MODULE__.Server.Router.s_call!(identifier, {:test_s_call!, value}, context)
  end

  def test_s_call(identifier, value, context) do
    __MODULE__.Server.Router.s_call(identifier, {:test_s_call, value}, context)
  end

  def test_s_cast!(identifier, value, context) do
    __MODULE__.Server.Router.s_cast!(identifier, {:test_s_cast!, value}, context)
  end

  def test_s_cast(identifier, value, context) do
    __MODULE__.Server.Router.s_cast(identifier, {:test_s_cast, value}, context)
  end

end # end defmodule GoldenRatio.Components.Gateway

