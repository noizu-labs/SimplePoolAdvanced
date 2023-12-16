defmodule Noizu.AdvancedPool.Support.NodeManager.ConfigurationProvider do
  @behaviour Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  require Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  import Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Support.{TestPool, TestPool2, TestPool3}

  def configuration(node) do
    case node do
      :nap_test_runner@localhost -> [TestPool, TestPool2]
      _ -> [TestPool2, TestPool3]
    end
    |> Enum.map(fn(service) ->
      test_pool_config = node_service(
        pool: service,
        node: node,
        priority: 0,
        supervisor_target: target_window(target: 3, low: 2, high: 4),
        worker_target: target_window(target: 6, low: 3, high: 9)
      )
      {service, test_pool_config}
    end)
    |> Map.new()
    |> then(&({:ok, &1}))
  end

  def test_service(service) do
    cluster_service(
      pool: service,
      priority: 1,
      node_target: target_window(target: 2, low: 1, high: 3),
      worker_target: target_window(target: 12, low: 6, high: 18)
    )
  end

  def configuration() do
    members = Enum.map(~W(a b c d e), & :"nap_test_member_#{&1}@localhost")
    test_cluster = [:nap_test_runner@localhost | members]

    cluster_node_settings = test_cluster
                            |> Enum.map(& {&1, configuration(&1)})
                            |> Enum.into(%{}, fn({k,{:ok, v}}) -> {k,v} end)
    [TestPool, TestPool2, TestPool3]
    |> Enum.into(%{},
         fn(service) ->
           service_node_configuration =
             cluster_node_settings
             |> Enum.filter(fn({_, x}) -> Enum.member?(x, service) end)
             |> Enum.into(%{}, fn({k, v}) -> {k, v[service]} end)
           {service, %{cluster: test_service(service), nodes: service_node_configuration}}
         end)
    |> then(&({:ok, &1}))
  end


  def cached(node), do: configuration(node)
  def cached(), do: configuration()

  def cache(node, _), do: configuration(node)
  def cache(_), do: configuration()
end
