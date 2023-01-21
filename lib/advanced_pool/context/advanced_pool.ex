defmodule Noizu.AdvancedPool do
  @moduledoc """
    Manages a standalone server or large cluster of persistent workers.
  """
  
  
  
  defmacro __using__(_) do
    quote do
      require Noizu.AdvancedPool.Server
      require Noizu.AdvancedPool.PoolSupervisor
      require Noizu.AdvancedPool.WorkerSupervisor
      require Noizu.AdvancedPool.Message

      @pool __MODULE__
      @pool_supervisor Module.concat([__MODULE__, PoolSupervisor])
      @pool_worker_supervisor Module.concat([__MODULE__, WorkerSupervisor])
      @pool_server Module.concat([__MODULE__, Server])
      @pool_registry Module.concat([__MODULE__, Registry])
      
      def __pool__(), do: @pool
      def __pool_supervisor__(), do: @pool_supervisor
      def __worker_supervisor__(), do: @pool_worker_supervisor
      def __server__(), do: @pool_server
      def __registry__(), do: @pool_registry
      
      def join_cluster() do
        :syn.add_node_to_scopes([__MODULE__])
      end
      
      def __cast_settings__(), do: Noizu.AdvancedPool.Message.settings(timeout: 5000)
      def __call_settings__(), do: Noizu.AdvancedPool.Message.settings(timeout: 60_000)
      def __dispatcher__(recipient, hint) do
        {:ok, __MODULE__}
      end
      
      def config() do
        [
        
        ]
      end
      
      def pool_spec(context, options \\ nil) do
        Noizu.AdvancedPool.DefaultSupervisor.pool_spec(__MODULE__, context, options)
      end


      def handle_call(msg, _from, state) do
        {:reply, {:uncaught, msg, state}, state}
      end
      def handle_cast(msg, state) do
        {:noreply, state}
      end
      def handle_info(msg, state) do
        {:noreply, state}
      end
    
    end
  end
end