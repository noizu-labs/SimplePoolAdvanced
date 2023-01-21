defmodule Noizu.AdvancedPool do
  @moduledoc """
    Manages a standalone server or large cluster of persistent workers.
  """
  
  require Record
  Record.defrecord(:pool_status, status: :initializing, service: nil, health: nil, node: nil, worker_count: 0, worker_target: nil, updated_on: nil)
  
  def default_worker_target(), do: 50_000
  
  def pool_scopes(pool) do
    [pool, apply(pool, :__server__, []), apply(pool, :__worker_supervisor__, []), apply(pool, :__worker__, [])]
  end
  
  def join_cluster(pool, node, pid, context, options) do
    config = apply(pool, :config, [])
    status = options[:pool][:init][:status] || config[:pool][:init][:status] || :offline
    target = options[:pool][:worker][:target] || config[:pool][:worker][:target] ||  Noizu.AdvancedPool.default_worker_target()
    time = cond do
             dt = options[:current_time] -> DateTime.to_unix(dt)
             :else -> :os.system_time(:second)
           end
    attributes = pool_status(status: status, service: pool,  health: :initializing, node: node, worker_count: 0, worker_target: target, updated_on: nil)
    :syn.add_node_to_scopes(apply(pool, :pool_scopes, []))
    :syn.join(pool, :nodes, pid, attributes)
    :syn.register(pool, node, pid, attributes)
    Noizu.AdvancedPool.NodeManager.register_pool(node, pid, attributes)
    Noizu.AdvancedPool.ClusterManager.register_pool(pid, attributes)
  end
  
  
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
      @pool_worker Module.concat([__MODULE__, Worker])
      @pool_registry Module.concat([__MODULE__, Registry])
      
      def __pool__(), do: @pool
      def __pool_supervisor__(), do: @pool_supervisor
      def __worker_supervisor__(), do: Noizu.AdvancedPool.WorkerSupervisor
      def __server__(), do: @pool_server
      def __worker__(), do: @pool_worker
      def __registry__(), do: @pool_registry
      
      
      
      def join_cluster(node, pid, context, options) do
        Noizu.AdvancedPool.join_cluster(__pool__(), node, pid, context, options)
      end
      
      def pool_scopes() do
        Noizu.AdvancedPool.pool_scopes(__pool__())
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
      
      def add_worker(context, options, temp_new \\ false) do
        # find node with best health metric.
        :syn.members(Noizu.AdvancedPool.Support.TestPool, :nodes)
        best_node = node()
        # find worker with best health metric or add additional worker if they are all over cap.
        l = :syn.members(Noizu.AdvancedPool.Support.TestPool, {best_node, :worker_supervisor})
        best_supervisor = cond do
                            temp_new ->
                              spec = __worker_supervisor__.spec(:os.system_time(:millisecond), __pool__(), context, options)
                              {:ok, pid} = Supervisor.start_child({Noizu.AdvancedPool.Support.TestPool, best_node}, spec)
                            :else ->
                              List.first(l) |> elem(0)
                          end
        # Call add child
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