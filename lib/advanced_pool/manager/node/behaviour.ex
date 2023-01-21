defmodule Noizu.AdvancedPool.NodeManager.Configuration do

end

defmodule Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour do
  @callback configuration(node) :: {:ok, term}
  @callback configuration() :: {:ok, term}

  require Record
  Record.defrecord(:target_window, target: nil, low: nil, high: nil)
  Record.defrecord(:node_service, state: :online, priority: nil, supervisor_target: nil, worker_target: nil, pool: nil, node: nil)
  Record.defrecord(:cluster_service, state: :online, priority: nil, node_target: nil, worker_target: nil, pool: nil)
end

defmodule Noizu.AdvancedPool.NodeManager.ConfigurationManager do
  def configuration(provider) do
    apply(provider, :configuration, [])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
  
  def configuration(provider, node) do
    apply(provider, :configuration, [node])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
end