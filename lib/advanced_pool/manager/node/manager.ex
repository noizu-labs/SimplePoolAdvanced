defmodule Noizu.AdvancedPool.NodeManager do
  @moduledoc """
  Manages node lifecycle and orchestration within the AdvancedPool framework. This module
  is responsible for handling node-specific actions such as configuration management,
  node activation, cluster participation, supervision, and health monitoring. It maintains
  the state of nodes and ensures their readiness to process workloads efficiently.

  Features include:
    - Active node health reporting based on operational context.
    - Configuration retrieval and caching for both global and node-specific settings.
    - Node initialization and activation with proper registration in the cluster's registry.
    - Worker supervisor registration to maintain worker process supervision and stability.
    - Dynamic node health assessment to facilitate load balancing and worker distribution.

  The NodeManager integrates closely with the ClusterManager to manage the AdvancedPool's
  distributed nature. Together, they provide a robust system for handling complex workloads
  across multiple nodes in the pool.

  ## Usage

  To interact with the NodeManager, utilize the following functions:

    - `service_available?/3`: Checks the availability of a specific service on a node.
    - `service_status/3`: Retrieves the operational status of a service attached to a node.
    - `health_report/2`: Requests a health report of the node within the specified context.
    - `configuration/2`: Fetches configuration details for the node.
    - `bring_online/2`: Activates the node and integrates it with the node manager system.
    - `register_worker_supervisor/4`: Registers a worker supervisor with the node manager.
    - `register_pool/4`: Integrates and tracks a pool's registration and status within the node manager.

  This module is central to maintaining the distributed pool's operational integrity, ensuring
  nodes are healthy, well-configured, and capable of supporting the pool's workload demands.
  """

  alias Noizu.AdvancedPool.Message.Dispatch, as: Router


  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message, only: [{:pool_status,1}, {:worker_sup_status,1}]

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
  def config(node) do
    with {:ok, config} <- apply(__configuration_provider__(), :cached, [node]) do
      {:ok, config}
    end
  end

  def ets_cluster_spec() do
    Noizu.AdvancedPool.SupervisorManagedEtsTableCluster.child_spec([:worker_events])
  end

  def set_service_status(pid, pool, node, status) do
    :syn.join(pool, :nodes, pid, status)
    :syn.register(pool, {:node, node}, pid, status)
    :syn.join(Noizu.AdvancedPool.NodeManager, {node, :services}, pid, status)
    :syn.register(Noizu.AdvancedPool.NodeManager, {node, pool}, pid, status)

    Noizu.AdvancedPool.ClusterManager.register_pool(pool, pid, status)
  end

  def service_available?(pool, node, context) do
    case service_status(pool, node, context) do
      {:ok, _} -> true
      :else -> false
    end
  end

  def service_status(pool, node, _context) do
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
    Router.s_call!({:ref, __server__(), node}, :health_report, context)
  end
  def configuration(node, context) do
    Router.s_call({:ref, __server__(), node}, :configuration, context)
  end

  def bring_online(node, context) do
    Task.Supervisor.async_nolink(__task_supervisor__(), fn() ->
      bring_online__inner(node, context)
    end)
  end

  def bring_online__inner(node, context) do
    cond do
      node == node() ->
        with cluster = %{} <- configuration(node, context) do
          # init
          Enum.map(
            cluster,
            fn({pool, _pool_config}) ->
              Noizu.AdvancedPool.NodeManager.Supervisor.add_child(apply(pool, :spec, [context]))
            end)
          # start
          Enum.map(
            cluster,
            fn({pool, _}) ->
              apply(pool, :bring_online, [context])
            end)

          # Ensure we have joined all pools - somewhat temp logic
          cluster_config = Noizu.AdvancedPool.ClusterManager.configuration(context)
          pools = Enum.map(cluster, fn({pool, _}) -> pool end)
          (Enum.map(cluster_config, fn({pool, _}) -> pool end) -- pools)
          |> Enum.map(
               fn(pool) ->
                 :syn.add_node_to_scopes([apply(pool, :__pool__, []), apply(pool, :__registry__, [])])
               end)

          # wait for services to come online.


        end
      :else ->
        :rpc.call(node, __MODULE__, :bring_online__inner, [node, context], :infinity)
    end
  end


  def register_worker_supervisor(pool, pid, _context, options) do
    config = apply(pool, :config, [])
    status = options[:worker_sup][:init][:status] || config[:worker_sup][:init][:status] || :online
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


  def register_pool(pool, pid, _context, options) do
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
    :syn.add_node_to_scopes([__pool__(), __registry__()])
    :syn.add_node_to_scopes(apply(pool, :pool_scopes, []))


    set_service_status(pid, pool, node, status)
  end

  def lock(_node, _context, _options) do
    :nyi
  end
  def release(_node, _context, _options) do
    :nyi
  end

end
