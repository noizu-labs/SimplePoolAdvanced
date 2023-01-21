defmodule Noizu.AdvancedPool.NodeManager do
  alias Noizu.AdvancedPool.Message.Dispatch, as: Router
  require Record
  require Noizu.AdvancedPool.Message
  Record.defrecord(:pool_status, status: :initializing, service: nil, health: nil, node: nil, worker_count: 0, worker_target: nil, updated_on: nil)


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
  
  def health_report(node, context) do
    Router.s_call({:ref, __server__(), node}, :health_report, context)
  end
  def configuration(node, context) do
    Router.s_call({:ref, __server__(), node}, :configuration, context)
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
    status = pool_status(status: status, service: pool,  health: :initializing, node: node, worker_count: 0, worker_target: target, updated_on: nil)
  
    :syn.add_node_to_scopes(apply(pool, :pool_scopes, []))
    :syn.join(pool, :nodes, pid, status)
    :syn.register(pool, {:node, node()}, pid, status)
    :syn.join(Noizu.AdvancedPool.NodeManager, {node, :services}, pid, status)
    Noizu.AdvancedPool.ClusterManager.register_pool(pool, pid, status)
  end
  
  
end