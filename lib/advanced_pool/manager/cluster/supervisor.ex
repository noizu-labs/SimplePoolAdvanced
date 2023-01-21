defmodule Noizu.AdvancedPool.ClusterManager.Supervisor do
  use Supervisor
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
    Supervisor.start_link(__MODULE__, {context, options}, name: __MODULE__)
  end
  
  def init({context, options}) do
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


end