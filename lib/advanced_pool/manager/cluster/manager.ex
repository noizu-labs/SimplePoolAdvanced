defmodule Noizu.AdvancedPool.ClusterManager do
  require Noizu.AdvancedPool.Message
  require Noizu.AdvancedPool.NodeManager
  alias Noizu.AdvancedPool.Message.Dispatch, as: Router
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
  
  def service_status(pool, context) do
    w = :syn.members(Noizu.AdvancedPool.ClusterManager, {:service, pool})
        |> Enum.map(&({Noizu.AdvancedPool.NodeManager.pool_status(elem(&1, 1), :node), {elem(&1, 0), elem(&1, 1)}}))
        |> Map.new()
    {:ok, w}
  end
  
  
end