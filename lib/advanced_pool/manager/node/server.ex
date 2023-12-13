defmodule Noizu.AdvancedPool.NodeManager.Server do
  @moduledoc """
  Represents the GenServer responsible for managing state and core functionalities of node management within
  the AdvancedPool framework. It performs essential tasks such as processing health reports, handling
  node-level configurations, and maintaining the node's registry within the pool's ecosystem.

  This server facilitates the health and configuration aspects of the NodeManager module. It is initiated
  as a GenServer and defines the setup and supervision of related processes. Additionally, it integrates
  with the Syn library for process registration and clustering of node information across the pool.

  ## Responsibilities

  The NodeManager.Server is tasked with:
    - Hosting the GenServer processes for node management activities.
    - Initializing the node's configuration and health reporting state.
    - Interacting with the configuration provider to handle node settings.
    - Establishing the initial state of the node registry for tracking and supervision purposes.
    - Being the communication endpoint for node-related synchronous and asynchronous messages and calls.

  This server works in conjunction with the NodeManager.Supervisor and other components of the AdvancedPool
  to support distributed functionality and offer fine-grained control over node operations and registrations.
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
  @pool Noizu.AdvancedPool.NodeManager
  defstruct [
    identifier: nil,
    health_report: :pending_node_report,
    node_config: [],
    meta: []
  ]
  
  Record.defrecord(:node_status, node: nil, status: nil, manager_state: nil, health_index: 0.0, started_on: nil, updated_on: nil)

  #===========================================
  # Config
  #===========================================
  def __configuration_provider__(), do: Noizu.AdvancedPool.NodeManager.__configuration_provider__()
  
  #===========================================
  # Server
  #===========================================
  def start_link(context, options) do
    Logger.warning("""
    INIT #{__MODULE__}#{inspect __ENV__.function}
    ***************************************


    """)
    GenServer.start_link(__MODULE__, {context, options}, name: __MODULE__)
  end

  def terminate(reason, state) do
    Logger.warning("""
    TERMINATE #{__MODULE__}#{inspect __ENV__.function}
    ***************************************
    #{inspect({reason, state})}
    """)
    :ok
  end
  
  def init({context, options}) do
    configuration = (with {:ok, configuration} <-
                            __configuration_provider__()
                            |> Noizu.AdvancedPool.NodeManager.ConfigurationManager.configuration(node()) do
                       configuration
                     else
                       e = {:error, _} -> e
                       error -> {:error, {:invalid_response, error}}
                     end)
    
    init_registry(context, options)
    {:ok, %Noizu.AdvancedPool.NodeManager.Server{identifier: node(), node_config: configuration}}
    |> IO.inspect(label: "START ADVANCED POOL NODE MANAGER SERVER")
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
    status = node_status(node: node(), status: :initilizing, manager_state: :init, health_index: 0.0, started_on: ts, updated_on: ts)
    refresh_registry(self(), status)
  end

  def refresh_registry(pid, status) do
    :syn.register(__pool__(), {:node_manager, node()}, pid, status)
    :syn.join(__pool__(), :node_managers, pid, status)
    apply(__dispatcher__(), :__register__, [__pool__(), {:ref, __MODULE__, node()}, pid, status])
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
  def __pool__(), do: Noizu.AdvancedPool.NodeManager
  def __server__(), do: Noizu.AdvancedPool.NodeManager.Server
  def __supervisor__(), do: Noizu.AdvancedPool.NodeManager.Supervisor
  def __dispatcher__(), do: apply(__pool__(), :__dispatcher__, [])
  def __registry__(), do: apply(__pool__(), :__registry__, [])

  #================================
  #
  #================================


  Noizu.AdvancedPool.NodeManager.Task
  #================================
  # Methods
  #================================
  
  
  def health_report(state, _context) do
    {:reply, state.health_report, state}
  end

  def configuration(state, _context) do
    {:reply, state.node_config, state}
  end
  
end
