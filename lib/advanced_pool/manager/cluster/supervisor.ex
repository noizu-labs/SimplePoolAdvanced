defmodule Noizu.AdvancedPool.ClusterManager.Supervisor do
  @moduledoc """
  Provides supervisory capabilities for processes within the ClusterManager scope of the AdvancedPool. This supervisor manages the lifecycle of the cluster's management server and task supervisor, ensuring they are started and remain operational.

  This module encapsulates the supervision strategy for cluster management, which includes:
    - Starting the ClusterManager server which oversees cluster-level state and operations.
    - Starting the Task Supervisor responsible for handling asynchronous tasks safely and efficiently.
    - Implementing the supervisory protocol to maintain resilience and recoverability for core cluster management components.

  The `ClusterManager.Supervisor` aligns the management processes under a unified supervision tree, applying a robust supervision strategy that affords reliability and fault tolerance within the context of AdvancedPool's distributed environment.
  """

  use Supervisor
  require Logger
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  
  def spec(context, options \\ nil) do
    %{
      id: __MODULE__,
      type: :supervisor,
      start: {__MODULE__, :start_link, [context, options]}
    }
  end
  
  def start_link(context, options) do
    Logger.info("""
    start_link #{__MODULE__}#{inspect __ENV__.function}
    ***************************************


    """)
    Supervisor.start_link(__MODULE__, {context, options}, name: __MODULE__)
  end
  
  def init({context, options}) do
    Logger.info("""
    INIT #{__MODULE__}#{inspect __ENV__.function}
    ***************************************


    """)
    # Setup Worker Event Tracker
    pool = apply(Noizu.AdvancedPool.ClusterManager, :__pool__, [])
    :ets.update_counter(:worker_events, {:service, pool}, {worker_events(:sup_init) + 1, 1}, worker_events(refreshed_on: :os.system_time(:millisecond)) |> put_in([Access.elem(0), Access.elem(1)], pool))

    init_registry(context, options)
    [
      {Task.Supervisor, name: Noizu.AdvancedPool.ClusterManager.Task},
      Noizu.AdvancedPool.ClusterManager.Server.spec(context, options)
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end


  #===========================================
  # Registry
  #===========================================
  def init_registry(_, _) do
    status = [node: node()]
    :syn.add_node_to_scopes([__pool__(), __registry__()])
    :syn.register(__pool__(), :supervisor, self(), status)
  end

  #================================
  # Behaviour
  #================================
  def __pool__(), do: Noizu.AdvancedPool.ClusterManager
  def __server__(), do: Noizu.AdvancedPool.ClusterManager.Server
  def __supervisor__(), do: Noizu.AdvancedPool.ClusterManager.Supervisor
  def __registry__(), do: Noizu.AdvancedPool.ClusterManager.WorkerRegistry

  def terminate(reason, state) do
    Logger.info("""
    TERMINATE #{__MODULE__}#{inspect __ENV__.function}
    ***************************************
    #{inspect({reason, state})}
    """)
    pool = apply(Noizu.AdvancedPool.ClusterManager, :__pool__, [])
    :ets.update_counter(:worker_events, {:service, pool}, {worker_events(:sup_terminate) + 1, 1}, worker_events(refreshed_on: :os.system_time(:millisecond)) |> put_in([Access.elem(0), Access.elem(1)], pool))

    :ok
  end

end
