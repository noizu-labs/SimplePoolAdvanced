defmodule Noizu.AdvancedPool.Support.NodeManager.ConfigurationProvider do
  @behaviour Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  require Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  import Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  def configuration(node) do
    test_pool_config = node_service(
      pool: Noizu.AdvancedPool.Support.TestPool,
      node: node,
      priority: 0,
      supervisor_target: target_window(target: 3, low: 2, high: 4),
      worker_target: target_window(target: 6, low: 3, high: 9),
    )
    %{
      Noizu.AdvancedPool.Support.TestPool => test_pool_config
    }
    |> then(&({:ok, &1}))
  end
  
  def configuration() do
    test_pool_config = cluster_service(
      pool: Noizu.AdvancedPool.Support.TestPool,
      priority: 1,
      node_target: target_window(target: 2, low: 1, high: 3),
      worker_target: target_window(target: 12, low: 6, high: 18),
    )
    cluster = %{
      "first@127.0.0.1": configuration(:"first@127.0.0.1") |> elem(1),
      "second@127.0.0.1": configuration(:"second@127.0.0.1")  |> elem(1)
    }
    
    %{
      Noizu.AdvancedPool.Support.TestPool =>
        %{
            cluster: test_pool_config,
            nodes: %{
              "first@127.0.0.1": cluster[:"first@127.0.0.1"][Noizu.AdvancedPool.Support.TestPool],
              "second@127.0.0.1": cluster[:"second@127.0.0.1"][Noizu.AdvancedPool.Support.TestPool]
            }
        }
    } |> then(&({:ok, &1}))
  end
end

