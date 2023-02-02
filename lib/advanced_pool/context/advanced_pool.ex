defmodule Noizu.AdvancedPool do
  @moduledoc """
    Manages a standalone server or large cluster of persistent workers.
  """
  
  require Record
  require Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M

  require Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  alias Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour, as: Config
  
  def default_worker_sup_target() do
    Config.target_window(low: 500, target: 2_500, high: 5_000)
  end
  def default_worker_target() do
    Config.target_window(low: 10_000, target: 50_000, high: 100_000)
  end
  
  def pool_scopes(pool) do
    [ pool,
      apply(pool, :__server__, []),
      apply(pool, :__worker_supervisor__, []),
      apply(pool, :__worker__, []),
      apply(pool, :__registry__, [])
    ]
  end
  
  def join_cluster(pool, pid, context, options) do
    Noizu.AdvancedPool.NodeManager.register_pool(pool, pid, context, options)
  end


  #----------------------------------------
  #
  #----------------------------------------
  @doc """
    Get direct link to worker.
  """
  def get_direct_link!(pool, M.ref() = ref, context, options \\ nil) do
    worker = apply(pool, :__worker__, [])
    with {:ok, ref} <- apply(worker, :ref_ok, [ref]) do
      with {:ok, {pid, attributes}} <- Noizu.AdvancedPool.DispatcherRouter.__lookup_worker_process__(ref) do
        M.link(node: attributes[:node], process: pid, recipient: ref)
      else
        _ ->
          M.link(node: nil, process: nil, recipient: ref)
      end
    else
      error -> {:error, {:invalid_ref, error}}
    end
  end
  
  defmacro __using__(_) do
    quote do
      require Noizu.AdvancedPool.Server
      require Noizu.AdvancedPool.WorkerSupervisor
      require Noizu.AdvancedPool.Message
            alias Noizu.AdvancedPool.Message, as: M
      require Noizu.AdvancedPool.NodeManager
      
      @pool __MODULE__
      @pool_supervisor Module.concat([__MODULE__, PoolSupervisor])
      @pool_worker_supervisor Module.concat([__MODULE__, WorkerSupervisor])
      @pool_server Module.concat([__MODULE__, Server])
      @pool_worker Module.concat([__MODULE__, Worker])
      @pool_registry Module.concat([__MODULE__, Registry])
      @pool_task_supervisor Module.concat([__MODULE__, Task])
      
      def __pool__(), do: @pool
      def __pool_supervisor__(), do: @pool_supervisor
      def __worker_supervisor__(), do: Noizu.AdvancedPool.WorkerSupervisor
      def __worker_server__(), do: Noizu.AdvancedPool.Worker.Server
      def __server__(), do: @pool_server
      def __worker__(), do: @pool_worker
      def __registry__(), do: @pool_registry
      def __task_supervisor__(), do: @pool_task_supervisor
      def __dispatcher__(), do: Noizu.AdvancedPool.DispatcherRouter

      def __cast_settings__(), do: Noizu.AdvancedPool.Message.settings(timeout: 5000)
      def __call_settings__(), do: Noizu.AdvancedPool.Message.settings(timeout: 60_000)



      def join_cluster(pid, context, options) do
        Noizu.AdvancedPool.join_cluster(__pool__(), pid, context, options)
      end
      
      def pool_scopes() do
        Noizu.AdvancedPool.pool_scopes(__pool__())
      end
      
      def config() do
        [
        
        ]
      end
      
      def spec(context, options \\ nil) do
        Noizu.AdvancedPool.DefaultSupervisor.spec(__MODULE__, context, options)
      end
      
      def get_direct_link!(ref, context, options \\ nil) do
        with {:ok, ref} <- apply(__worker__(), :ref_ok, [ref]) do
          Noizu.AdvancedPool.get_direct_link!(__pool__(), ref, context, options)
        end
        
        
      end

      def bring_online(context) do
        # Temp Logic.
        with {pid, status} <- :syn.lookup(Noizu.AdvancedPool.NodeManager, {node(), __pool__()}) do
          updated_status = Noizu.AdvancedPool.NodeManager.pool_status(status, status: :online, health: 1.0)
          :syn.register(Noizu.AdvancedPool.NodeManager, {node(), __pool__()}, pid, updated_status)
          :syn.join(Noizu.AdvancedPool.ClusterManager, {:service, __pool__()}, pid, updated_status)
          
        end
        # |> IO.inspect(label: "bring_online: #{__pool__()}")


        



      end
      
      def add_worker_supervisor(node, spec) do
        Noizu.AdvancedPool.DefaultSupervisor.add_worker_supervisor(__MODULE__, node, spec)
      end
      
      def add_worker(context, options, temp_new \\ false) do
        # find node with best health metric.
        :syn.members(Noizu.AdvancedPool.Support.TestPool, :nodes)
        best_node = node()
        # find worker with best health metric or add additional worker if they are all over cap.
        l = :syn.members(Noizu.AdvancedPool.Support.TestPool, {best_node, :worker_supervisor})
        best_supervisor = cond do
                            temp_new ->
                              spec = __worker_supervisor__.spec(:os.system_time(:nanosecond), __pool__(), context, options)
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

      def s_call!(identifier, message, context) do
        with {:ok, ref} <- apply(__worker__(), :recipient, [identifier]) do
          Noizu.AdvancedPool.Message.Dispatch.s_call!(ref, message, context)
        end
      end
      def s_call(identifier, message, context) do
        with {:ok, ref} <- apply(__worker__(), :recipient, [identifier]) do
          Noizu.AdvancedPool.Message.Dispatch.s_call!(ref, message, context)
        end
      end

      def s_cast!(identifier, message, context) do
        with {:ok, ref} <- apply(__worker__(), :recipient, [identifier]) do
          Noizu.AdvancedPool.Message.Dispatch.s_cast!(ref, message, context)
        end
      end
      def s_cast(identifier, message, context) do
        with {:ok, ref} <- apply(__worker__(), :recipient, [identifier]) do
          Noizu.AdvancedPool.Message.Dispatch.s_cast(ref, message, context)
        end
      end
      
      def reload!(ref, context, options), do: s_call!(ref, {:reload!, options}, context)
      def fetch(ref, type, context), do: s_call!(ref, {:fetch, type}, context)
      def ping(ref, context), do: s_call(ref, :ping, context)
      def ping(ref, context, options), do: s_call(ref, {:ping, options}, context)
      def kill!(ref, context, options), do: s_call(ref, {:kill!, options}, context)
      def crash!(ref, context, options), do: s_call(ref, {:crash!, options}, context)
      def hibernate(ref, context, options), do: s_call!(ref, {:hibernate, options}, context)
      def persist!(ref, context, options), do: s_call!(ref, {:persist!, options}, context)

      defoverridable [
        __pool__: 0,
        __pool_supervisor__: 0,
        __worker_supervisor__: 0,
        __worker_server__: 0,
        __server__: 0,
        __worker__: 0,
        __registry__: 0,
        __task_supervisor__: 0,
        __dispatcher__: 0,
        __cast_settings__: 0,
        __call_settings__: 0,
        join_cluster: 3,
        pool_scopes: 0,
        config: 0,
        spec: 1,
        spec: 2,
        get_direct_link!: 2,
        get_direct_link!: 3,
        bring_online: 1,
        add_worker_supervisor: 2,
        add_worker: 2,
        add_worker: 3,
        handle_call: 3,
        handle_cast: 2,
        handle_info: 2,
  
        reload!: 3,
        fetch: 3,
        ping: 3,
        ping: 2,
        kill!: 3,
        crash!: 3,
        hibernate: 3,
        persist!: 3,
      ]
      
    end
  end
end