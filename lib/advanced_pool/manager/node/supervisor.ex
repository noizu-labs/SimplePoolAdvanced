defmodule Noizu.AdvancedPool.NodeManager.Supervisor do
  @moduledoc """
  Acts as the main supervisory entity within the NodeManager domain, controlling the initiation and
  oversight of node management processes. This module is responsible for the supervision of the GenServer
  that manages node configurations, health checks, and registry updates.

  Key features and responsibilities:
    - Launching the NodeManager's GenServer and Task Supervisor, thereby starting the node management processes.
    - Implementing a supervisory structure that ensures resilience and fault tolerance for node management components.
    - Dynamic addition of child processes to the NodeManager's supervisory tree, allowing flexibility in process management.
    - Interfacing with the Syn library for process and node registry within scopes and enabling node identification and management in the larger pool structure.

  The NodeManager.Supervisor encapsulates the supervisory logic necessary for AdvancedPool's nodal operations,
  underpinning the robustness and reliability of the node management system. Through coordination with servers,
  dispatchers, and registries, this supervisor maintains a clean and responsive state across node-specific services.
  """

  use Supervisor
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  require Logger
  def spec(context, options \\ nil) do
    %{
      id: __MODULE__,
      type: :supervisor,
      start: {__MODULE__, :start_link, [context, options]}
    }
  end
  
  def start_link(context, options) do
    Logger.info("""
    INIT #{__MODULE__}#{inspect __ENV__.function}
    ***************************************


    """)
    Supervisor.start_link(__MODULE__, {context, options}, name: __MODULE__)
  end
  
  def init({context, options}) do
    Logger.info("""
    INIT #{__MODULE__}#{inspect __ENV__.function}
    ***************************************


    """)
    init_registry(context, options)
    [
      {Task.Supervisor, name: Noizu.AdvancedPool.NodeManager.Task},
      Noizu.AdvancedPool.NodeManager.Server.spec(context, options)
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end

  def terminate(reason, state) do
    Logger.info("""
    TERMINATE #{__MODULE__}#{inspect __ENV__.function}
    ***************************************
    #{inspect({reason, state})}
    """)
    :ok
  end

  def add_child(spec) do

    Logger.info("""
    ADD CHILD #{__MODULE__}#{inspect __ENV__.function}
    ***************************************
    #{inspect spec}

    """)

    Supervisor.start_child(__MODULE__, spec)
  end


  #===========================================
  # Registry
  #===========================================
  def init_registry(_, _) do
    status = [node: node()]
    :syn.add_node_to_scopes([__cluster_pool__(), __cluster_registry__(), __pool__(), __registry__()])
    :syn.register(__pool__(), {:supervisor, node()}, self(), status)
    :syn.join(__pool__(), :supervisors, self(), status)
  end

  #================================
  # Behaviour
  #================================
  def __pool__(), do: Noizu.AdvancedPool.NodeManager
  def __server__(), do: Noizu.AdvancedPool.NodeManager.Server
  def __supervisor__(), do: Noizu.AdvancedPool.NodeManager.Supervisor
  def __registry__(), do: Noizu.AdvancedPool.NodeManager.WorkerRegistry


  defdelegate __cluster_pool__(), to: Noizu.AdvancedPool.ClusterManager, as: :__pool__
  defdelegate __cluster_server__(), to: Noizu.AdvancedPool.ClusterManager, as: :__server__
  defdelegate __cluster_supervisor__(), to: Noizu.AdvancedPool.ClusterManager, as: :__supervisor__
  defdelegate __cluster_registry__(), to: Noizu.AdvancedPool.ClusterManager, as: :__registry__


end
