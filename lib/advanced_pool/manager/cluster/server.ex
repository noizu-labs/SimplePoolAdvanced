defmodule Noizu.AdvancedPool.ClusterManager.Server do
  @moduledoc """
  Hosts the GenServer process for the ClusterManager in the AdvancedPool framework, managing the cluster's state and core functions related to cluster-level configurations and health reporting. This server is the centralized component that handles queries and actions related to the overall health and configuration state of the cluster.

  Serving as a crucial part of cluster-level operations, it is responsible for the following tasks:
    - Initializing and maintaining the cluster's configurations as provided by the configuration provider.
    - Interfacing with the Syn library for cluster-wide process registry and management.
    - Handling health report inquiries and returning the current health status of the cluster.
    - Processing configuration requests and delivering the cluster's configuration settings.

  Through the interplay of initialization, registry maintenance, and message handling, the ClusterManager.Server provides a robust methodology for managing the state and operability of clusters in a distributed pool environment.
  """

  use GenServer
  require Record
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  require Logger
  alias Noizu.AdvancedPool.Message.Handle, as: MessageHandler
  
  #===========================================
  # Struct
  #===========================================
  
  defstruct [
    health_report: nil,
    previous_health_report: nil,
    cluster_config: [],
    meta: []
  ]

  #===========================================
  # Config
  #===========================================
  def __configuration_provider__(), do: Noizu.AdvancedPool.ClusterManager.__configuration_provider__()
  
  #===========================================
  # Server
  #===========================================
  def start_link(context, options) do
    GenServer.start_link(__MODULE__, {context, options}, name: __MODULE__)
  end

  def init({context, options}) do
    Logger.info("""
    INIT #{__MODULE__}#{inspect __ENV__.function}
    ***************************************

    """)
    configuration = (with {:ok, configuration} <-
                            __configuration_provider__()
                            |> Noizu.AdvancedPool.NodeManager.ConfigurationManager.configuration() do
                       configuration
                     else
                       e = {:error, _} -> e
                       error -> {:error, {:invalid_response, error}}
                     end)
    init_registry(context, options)
    {:ok, %Noizu.AdvancedPool.ClusterManager.Server{cluster_config: configuration}}

  end

  def terminate(reason, state) do
    Logger.info("""
    TERMINATE #{__MODULE__}#{inspect __ENV__.function}
    ***************************************
    #{inspect({reason, state})}
    """)
    :ok
  end
  
  def spec(context, options \\ nil) do
    %{
      id: __MODULE__,
      type: :worker,
      start: {__MODULE__, :start_link, [context, options]}
    }
  end
  
  #===========================================
  # Registry
  #===========================================
  def init_registry(_, _) do
    ts = :os.system_time(:second)
    status = cluster_status(node: node(), status: :initilizing, manager_state: :init, health_index: 0.0, started_on: ts, updated_on: ts)
    refresh_registry(self(), status)
  end

  def refresh_registry(pid, status) do
    :syn.register(__pool__(), :manager, pid, status)
    apply(__dispatcher__(), :__register__, [__pool__(), {:ref, __MODULE__, :manager}, pid, status])
  end
  
  #================================
  # Routing
  #================================
  
  #-----------------------
  #
  #-----------------------
  def handle_call(msg_envelope() = call, from, state) do
    MessageHandler.unpack_call(call, from, state)
  end
  def handle_call(s(call: {:health_report, subscriber}, context: context), _, state) do
    health_report(state, subscriber, context)
  end

  def handle_call(s(call: :configuration, context: context), _, state) do
    configuration(state, context)
  end
  def handle_call(call, from, state), do: MessageHandler.uncaught_call(call, from, state)
  
  #-----------------------
  #
  #-----------------------
  def handle_cast(msg_envelope() = call, state) do
    MessageHandler.unpack_cast(call, state)
  end
  def handle_cast(s(call: {:update_health_report, report}, context: context), state) do
    update_health_report(state, report, context)
  end
  def handle_cast(call, state), do: MessageHandler.uncaught_cast(call, state)
  
  #-----------------------
  #
  #-----------------------
  def handle_info(msg_envelope() = call, state) do
    MessageHandler.unpack_info(call, state)
  end
  def handle_info(call, state), do: MessageHandler.uncaught_info(call, state)


  #================================
  # Behaviour
  #================================
  def __pool__(), do: Noizu.AdvancedPool.ClusterManager
  def __server__(), do: Noizu.AdvancedPool.ClusterManager.Server
  def __supervisor__(), do: Noizu.AdvancedPool.ClusterManager.Supervisor
  def __dispatcher__(), do: apply(__pool__(), :__dispatcher__, [])
  def __registry__(), do: apply(__pool__(), :__registry__, [])
  #================================
  # Methods
  #================================

  #----------------
  # health_report/2
  #----------------
  def health_report(state, receiver, context) do
    with true <- !Noizu.AdvancedPool.ClusterManager.HealthReport.processing?(state.health_report) || :processing,
         {:ok, state} <- request_health_report(state, receiver, context) do
      {:reply, {:ok, state.previous_health_report || :initializing}, state}
    else
      :processing ->
        update_in(state, [Access.key(:health_report), Access.key(:subscribers)], & [receiver, &1])
        {:reply, {:ok, state.health_report}, state}
      error = {:error, _} -> {:reply, error, state}
      error -> {:reply, {:error, error}, state}
    end
  end

  #----------------
  # update_health_report/3
  #----------------
  def update_health_report(state, report, _context) do
    health_report = unless state.health_report do
      %Noizu.AdvancedPool.ClusterManager.HealthReport{
        worker: nil,
        started_at: DateTime.utc_now(),
        status: :processing,
      }
      else
      state.health_report
    end

    health_report = %Noizu.AdvancedPool.ClusterManager.HealthReport{health_report|
      finished_at: DateTime.utc_now(),
      report: report,
      status: :ready,
    }

    # Call Config Manager - # todo verify :ok response
    apply(__configuration_provider__(), :report_cluster_health, [report])

    state = state
            |> put_in([Access.key(:health_report)], health_report)

    Enum.map(health_report.subscribers || [], fn(r) ->
      spawn fn ->
        send(r, {:health_report, health_report})
      end
    end)

    {:noreply, state}
  end

  #----------------
  # request_health_report/2
  #----------------
  defp request_health_report(state, subscriber, context) do
    worker = Task.Supervisor.async_nolink(Noizu.AdvancedPool.ClusterManager.Task, __MODULE__, :do_build_health_report, [context])
    health_report = %Noizu.AdvancedPool.ClusterManager.HealthReport{
      worker: worker,
      subscribers: [subscriber],
      status: :processing,
      started_at: DateTime.utc_now(),
    }
    state = state
            |> put_in([Access.key(:previous_health_report)], state.health_report)
            |> put_in([Access.key(:health_report)], health_report)
    {:ok, state}
  end

  #----------------
  # do_build_health_report/1
  #----------------
  def do_build_health_report(context) do
    context = Noizu.ElixirCore.CallingContext.system(context)
    with {:ok, config} <- Noizu.AdvancedPool.ClusterManager.config() do
      cluster = Enum.map(config, fn {_pool, pconfig} ->
        Enum.map(pconfig[:nodes], fn {node, _nconfig} ->
          node
        end)
      end) |> List.flatten()
      cluster = (cluster ++ [node() | Node.list()]) |> Enum.uniq()
      # Task process and update health report to track progress
      report = Enum.map(cluster, &{&1,  Noizu.AdvancedPool.NodeManager.health_report(&1, context)})
               |> Map.new()
      Noizu.AdvancedPool.ClusterManager.update_health_report(report, context)
    end
    # rescue/else health_report_error ...
  end

  #----------------
  # configuration/2
  #----------------
  def configuration(state, _context) do
    {:reply, state.cluster_config, state}
  end
  
end
