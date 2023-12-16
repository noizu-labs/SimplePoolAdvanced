defmodule Noizu.AdvancedPool.ClusterManager do
  @moduledoc """
  Oversees the coordination and management of a distributed set of nodes within the AdvancedPool.
  Handles cluster-wide configurations and supervises cluster operations, including worker process
  distribution, node health reports, and configuration retrieval at the cluster level.

  The ClusterManager serves as a higher-level entity that interacts with NodeManagers to orchestrate
  the activities across multiple nodes, ensuring an efficient and unified environment for varied
  workloads. It facilitates critical cluster-level operations such as node selection based on health
  metrics and workload distribution strategies, contributing to the overall scalability and resilience
  of the system.

  Key responsibilities:
    - Cluster-wide health assessment through the collection of individual node health reports.
    - Management of cluster-wide settings to maintain consistent configurations across nodes.
    - Registration and supervision of pools within the cluster, promoting synchronized operations.
    - Determination of optimal nodes and worker supervisors for process instantiation, ensuring balanced load distribution.
    - Coordination of worker start-up at the cluster level, taking into account parameters such as stickiness and capacity thresholds.

  ## Interface

  Modules and functions typically used in interaction with ClusterManager include:
    - `health_report/1`: Initiates health reporting procedures for the cluster.
    - `configuration/1`: Provides access to the cluster's configuration parameters.
    - `register_pool/3`: Registers a new pool to the cluster for management and supervision.
    - `service_status/2`: Reports on the service status of pools within the cluster.
    - `start_worker/5`: Handles the start-up of worker processes within the cluster based on specific settings and node targets.
    - `as_task/3`: Determines the mode of operation for cluster tasks, either natively or through a specified task supervisor.
  """

  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  require Noizu.AdvancedPool.NodeManager
  require Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  import Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  
  require Noizu.AdvancedPool.NodeManager
  import Noizu.AdvancedPool.NodeManager, only: [
    pool_status: 1, pool_status: 2,
    worker_sup_status: 1
  ]
  alias Noizu.AdvancedPool.Message.Dispatch, as: Router
  alias Noizu.AdvancedPool.NodeManager
  alias Noizu.AdvancedPool.NodeManager.ConfigurationManager

  def __configuration_provider__(), do: Application.get_env(:noizu_advanced_pool, :configuration)
  
  def __task_supervisor__(), do: Noizu.AdvancedPool.ClusterManager.Task
  def __pool__(), do: Noizu.AdvancedPool.ClusterManager
  def __server__(), do: Noizu.AdvancedPool.ClusterManager.Server
  def __supervisor__(), do: Noizu.AdvancedPool.ClusterManager.Supervisor
  def __dispatcher__(), do: Noizu.AdvancedPool.DispatcherRouter
  def __registry__(), do: Noizu.AdvancedPool.ClusterManager.WorkerRegistry
  def __cast_settings__(), do: Noizu.AdvancedPool.Message.settings(timeout: 5000)
  def __call_settings__(), do: Noizu.AdvancedPool.Message.settings(timeout: 60_000)
  def spec(context, options \\ nil), do: apply(__supervisor__(), :spec, [context, options])
  def config() do
    []
  end
  
  def health_report(context) do
    Router.s_call({:ref, __server__(), :manager}, :health_report, context)
  end
  def configuration(context) do
    Router.s_call({:ref, __server__(), :manager}, :configuration, context)
  end

  def register_pool(pool, pid, status) do
    :syn.join(Noizu.AdvancedPool.ClusterManager, {:service, pool}, pid, status)
  end
  
  def service_status(pool, _context) do
    w = :syn.members(Noizu.AdvancedPool.ClusterManager, {:service, pool})
        |> Enum.map(&({pool_status(elem(&1, 1), :node), {elem(&1, 0), elem(&1, 1)}}))
        |> Map.new()
    {:ok, w}
  end


  def as_task(_, {:with, :native}, _), do: :native
  def as_task(_, {:with, task_supervisor}, _), do: {:ok, task_supervisor}
  def as_task(pool, _, context) do
    with {:ok, {_,_status}} <- NodeManager.service_status(pool, node(), context) do
      {:ok, apply(pool, :__task_supervisor__, [])}
    else
      _ -> {:ok, __task_supervisor__()}
    end
  end
  
  def start_worker(pool, ref, settings, context, options) do
    cond do
      v = options[:return_task] ->
        with {:ok, ts} <- as_task(pool, v, context) do
          Task.Supervisor.async_nolink(ts, __MODULE__, :do_start_worker, [pool, ref, settings, context, options])
          else
          :native -> Task.async(__MODULE__, :do_start_worker, [pool, ref, settings, context, options])
        end
      :else ->
        do_start_worker(pool, ref, settings, context, options)
    end
  end
  
  def do_start_worker(pool, ref, settings, context, options) do
    # 1. Pick best node - taking into account sticky setting.
    with {:ok, node} <- pick_node(pool, ref, settings, context, options),
         {:ok, sup} <- pick_supervisor(node, pool, ref, settings, context, options) do
      worker_server = apply(pool, :__worker_server__, [])
      spec = apply(worker_server, :spec, [ref, [], context])

      worker_supervisor = apply(pool, :__worker_supervisor__, [])
      apply(worker_supervisor, :add_worker, [sup, spec])
      # |> IO.inspect(label: "#{pool}.add_worker #{inspect ref}")
    end
  end

  def default_health_target() do
    target_window(low: 0.75, target: 0.9, high: 1.00)
  end


  defp ws_low(available) do
    Enum.filter(available, fn({_, worker_sup_status(worker_count: wc, worker_target: target_window(low: check))}) ->
      wc <= check
    end)
  end

  defp ws_target(available) do
    Enum.filter(available, fn({_, worker_sup_status(worker_count: wc, worker_target: target_window(target: check))}) ->
      wc <= check
    end)
  end

  defp ws_high(available) do
    Enum.filter(available, fn({_, worker_sup_status(worker_count: wc, worker_target: target_window(high: check))}) ->
      wc <= check
    end)
  end
  
  def pick_supervisor(node, pool, ref, _settings, context, options) do
    # randomly pick any worker supervisor for this pool that hasn't hit it's high cap yet.
    # if none exist add a new supervisor to pool.
    
    available = :syn.members(pool, {node, :worker_sups})
    #|> IO.inspect(label: "#{pool} - available worker supervisors")
    cond do
      (
        avail = ws_low(available)
        length(avail) > 0
        ) ->
        sup = Enum.random(avail) |> elem(0)
        {:ok, sup}
      (
        avail = ws_target(available)
        length(avail) > 0
        ) ->
        sup = Enum.random(avail) |> elem(0)
        {:ok, sup}
      (
        avail = ws_high(available)
        length(avail) > 0
        ) ->
        sup = Enum.random(avail) |> elem(0)
        {:ok, sup}
      :else ->
        # start new supervisor.
        # IO.puts "START NEW SUP"
        #supervisor = apply(pool, :config, [])[:otp][:supervisor] || Noizu.AdvancedPool.DefaultSupervisor
        worker_supervisor = apply(pool, :__worker_supervisor__, [])
        spec = apply(worker_supervisor, :spec, [ref, pool, context, options])
        with {:ok, sup} <- apply(pool, :add_worker_supervisor, [node, spec]) do
          {:ok, sup}
        end
    end
  end
  
  def pick_threshold(pool, settings, context, options) do
    cond do
      v = options[:sticky?] || sticky?(settings) ->
        # verify service is available
        cond do
          NodeManager.service_available?(pool, node(), context) ->
             cond do
              is_float(v) -> {:sticky, v}
              :else ->
                v = (with {:ok, config} <- __configuration_provider__() |> ConfigurationManager.cached(),
                          %{cluster: cluster_config, nodes: node_config} <- config[pool] do
                       (with node_service(health_target: target_window(low: v)) <- node_config[node()],
                             true <- is_float(v) do
                          v
                        else
                          _ ->
                            (with cluster_service(health_target: target_window(low: v)) <- cluster_config,
                                  true <- is_float(v) do
                               v
                             else
                               _ -> target_window(default_health_target(), :low)
                             end)
                        end)
                     else
                       _ -> target_window(default_health_target(), :low)
                     end)
                {:sticky, v}
             end
          :else ->
            v = with {:ok, config} <- __configuration_provider__() |> ConfigurationManager.cached(),
                 %{cluster: cluster_service(health_target: target = target_window())} <- config[pool] do
              target || default_health_target()
            end
            {:best, v}
        end
      :else ->
        v = with {:ok, config} <- __configuration_provider__() |> ConfigurationManager.cached(),
             %{cluster: cluster_service(health_target: target = target_window())} <- config[pool] do
             target || default_health_target()
        end
        {:best, v}
    end
  end
  
  def pick_node(pool, ref, settings, context, options) do
    case pick_threshold(pool, settings, context, options) do
      {:pick, t} ->
        with {:ok, {_, pool_status(status: :online, health: health_value)}} <- NodeManager.service_status(pool, node(), context),
             true <- t <= health_value  do
          {:ok, node()}
        else
          _ -> best_node(pool, ref, settings, context, options)
        end
      {:sticky, t} ->
        with {:ok, {_, pool_status(status: :online, health: health_value)}} <- NodeManager.service_status(pool, node(), context),
             true <- t <= health_value  do
          {:ok, node()}
        else
          _ -> best_node(pool, ref, settings, context, options)
        end
      {:best, _} -> best_node(pool, ref, settings, context, options)
    end
  end
  
  def best_node(pool, _ref, _settings, _context, _options) do
    available = :syn.members(Noizu.AdvancedPool.ClusterManager, {:service, pool})
                |> Enum.filter(&(pool_status(elem(&1,1), :status) == :online))
                |> Enum.map(
                     fn(a) ->
                       pool_status(health: ah, worker_count: awc, worker_target: target_window(target: aw_t, low: aw_l, high: aw_h)) = elem(a, 1)
                       
                       
                       # group health into 20 buckets.
                       health_percent = ah
                       worker_bonus = cond do
                                          awc <= aw_t -> (1 - ((awc - aw_l) / (aw_t - aw_l)))
                                          :else -> 0
                                        end
                       worker_capacity =  (1 - ((awc - aw_l) / (aw_h - aw_l)))
                       grade = (((health_percent + worker_bonus)*0.75) + ((health_percent * worker_capacity)*0.25))
                       grade = round(grade * 100)
                       {a,grade}
                     end)
                |> Enum.sort_by(&(elem(&1, 1)), :desc)

    l = length(available)
    cond do
      l > 0 ->
        t_q = max(div(length(available), 5), 3)
        v = Enum.slice(available, 0..t_q)
            |> Enum.random()
            |> elem(0)
            |> elem(1)
            |> pool_status(:node)
        {:ok, v}
      :else -> {:error, :unavailable}
    end
  end

  def lock_pool(pool, node, context, options \\ nil) do
    NodeManager.lock_pool(pool, node, context, options)
  end

  def release_pool(pool, node, context, options \\ nil) do
    NodeManager.release_pool(pool, node, context, options)
  end


  def lock_node(node, context, options \\ nil) do
    NodeManager.lock(node, context, options)
  end

  def release_node(node, context, options \\ nil) do
    NodeManager.release(node, context, options)
  end
  
  
end
