defmodule Noizu.AdvancedPool.NodeManager do
  alias Noizu.AdvancedPool.Message.Dispatch, as: Router
  require Record
  require Noizu.AdvancedPool.Message
  Record.defrecord(
    :pool_status,
    status: :initializing,
    service: nil,
    health: nil,
    node: nil,
    worker_count: 0,
    worker_target: nil,
    updated_on: nil
  )
  Record.defrecord(
    :worker_sup_status,
    status: :initializing,
    service: nil,
    health: nil,
    node: nil,
    worker_count: 0,
    worker_target: nil,
    updated_on: nil
  )
  
  def __configuration_provider__(), do: Application.get_env(:noizu_advanced_pool, :configuration)
  
  def __task_supervisor__(), do: Noizu.AdvancedPool.NodeManager.Task
  def __pool__(), do: Noizu.AdvancedPool.NodeManager
  def __server__(), do: Noizu.AdvancedPool.NodeManager.Server
  def __supervisor__(), do: Noizu.AdvancedPool.NodeManager.Supervisor
  def __dispatcher__(), do: Noizu.AdvancedPool.DispatcherRouter
  def __registry__(), do: Noizu.AdvancedPool.NodeManager.WorkerRegistry
  def __cast_settings__(), do: Noizu.AdvancedPool.Message.settings(timeout: 5000)
  def __call_settings__(), do: Noizu.AdvancedPool.Message.settings(timeout: 60_000)
  def spec(context, options \\ nil), do: apply(__supervisor__(), :spec, [context, options])
  def config() do
    []
  end


  def service_available?(pool, node, context) do
    case service_status(pool, node, context) do
      {:ok, _} -> true
      :else -> false
    end
  end
  
  def service_status(pool, node, context) do
    with {pid, status} <- :syn.lookup(pool, {:node, node}) do
      {:ok, {pid, status}}
    else
      _ -> {:error, pool}
    end
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
  
  def health_report(node, context) do
    Router.s_call({:ref, __server__(), node}, :health_report, context)
  end
  def configuration(node, context) do
    Router.s_call({:ref, __server__(), node}, :configuration, context)
  end
  def bring_online(node, context) do
    cond do
      (node == node()) ->
        with cluster = %{} <- configuration(node, context) do
          Task.Supervisor.async_nolink(__task_supervisor__(), fn() ->
            # init
            Enum.map(
              cluster,
              fn({pool, pool_config}) ->
                Noizu.AdvancedPool.NodeManager.Supervisor.add_child(apply(pool, :spec, [context]))
              end)
            # start
            Enum.map(
              cluster,
              fn({pool, _}) ->
                apply(pool, :bring_online, [context])
              end)
            
              # wait for services to come online.
          end)
        end
      :else -> :rpc.call(node, __MODULE__, :bring_node_online, [node, context])
    end
  end
  
  
  def register_worker_supervisor(pool, pid, context, options) do
    config = apply(pool, :config, [])
    status = options[:worker_sup][:init][:status] || config[:worker_sup][:init][:status] || :offline
    target = options[:worker_sup][:worker][:target] || config[:worker_sup][:worker][:target] ||  Noizu.AdvancedPool.default_worker_sup_target()
    time = cond do
             dt = options[:current_time] -> DateTime.to_unix(dt)
             :else -> :os.system_time(:second)
           end
    node = node()
    status = worker_sup_status(
      status: status,
      service: pool,
      health: :initializing,
      node: node,
      worker_count: 0,
      worker_target: target,
      updated_on: time
    )
    :syn.join(pool, {node(), :worker_sups}, pid, status)
    :syn.join(Noizu.AdvancedPool.NodeManager, {node, pool, :worker_sups}, pid, status)
  end
  
  
  def register_pool(pool, pid, context, options) do
    config = apply(pool, :config, [])
    status = options[:pool][:init][:status] || config[:pool][:init][:status] || :offline
    target = options[:pool][:worker][:target] || config[:pool][:worker][:target] ||  Noizu.AdvancedPool.default_worker_target()
    time = cond do
             dt = options[:current_time] -> DateTime.to_unix(dt)
             :else -> :os.system_time(:second)
           end
    node = node()
    status = pool_status(
      status: status,
      service: pool,
      health: :initializing,
      node: node,
      worker_count: 0,
      worker_target: target,
      updated_on: time
    )
  
    :syn.add_node_to_scopes(apply(pool, :pool_scopes, []))
    :syn.join(pool, :nodes, pid, status)
    :syn.register(pool, {:node, node()}, pid, status)
    #|> IO.inspect(label: :register)
    :syn.join(Noizu.AdvancedPool.NodeManager, {node, :services}, pid, status)
    :syn.register(Noizu.AdvancedPool.NodeManager, {node, pool}, pid, status)
    Noizu.AdvancedPool.ClusterManager.register_pool(pool, pid, status)
  end
  
  
end