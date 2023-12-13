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
  @pool Noizu.AdvancedPool.ClusterManager
  defstruct [
    health_report: :pending_cluster_report,
    cluster_config: [],
    meta: []
  ]
  
  Record.defrecord(:cluster_status, node: nil, status: nil, manager_state: nil, health_index: 0.0, started_on: nil, updated_on: nil)


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
  def handle_call(s(call: :health_report, context: context), _, state) do
    health_report(state, context)
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
  def health_report(state, _context) do
    {:reply, state.health_report, state}
  end

  def configuration(state, _context) do
    {:reply, state.cluster_config, state}
  end
  
end
