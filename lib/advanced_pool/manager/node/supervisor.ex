defmodule Noizu.AdvancedPool.NodeManager.Supervisor do
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
      {Task.Supervisor, name: Noizu.AdvancedPool.NodeManager.Task},
      Noizu.AdvancedPool.NodeManager.Server.spec(context, options)]
    |> Supervisor.init(strategy: :one_for_one)
  end
  
  def add_child(spec) do
    Supervisor.start_child(__MODULE__, spec)
  end


  #===========================================
  # Registry
  #===========================================
  def init_registry(_, _) do
    status = [node: node()]
    :syn.add_node_to_scopes([__pool__(), __registry__()])
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


end