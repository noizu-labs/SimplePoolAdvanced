defmodule Noizu.AdvancedPool.Support.NodeManager.ConfigurationProvider do
  @behaviour Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  require Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  import Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Support.{TestPool, TestPool2, TestPool3, TestPool4, TestPool5, TestPool6, TestPool7}

  def configuration(node) do
    case node do
      :nap_test_runner@localhost -> [TestPool, TestPool2, TestPool4, TestPool5, TestPool6, TestPool7]
      _ -> [TestPool2, TestPool3, TestPool4, TestPool5, TestPool6, TestPool7]
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
    [TestPool, TestPool2, TestPool3, TestPool4, TestPool5, TestPool6, TestPool7]
    |> Enum.into(%{},
         fn(service) ->
           service_node_configuration =
             cluster_node_settings
             |> Enum.filter(fn({_node, x}) -> get_in(x, [service]) && true || false end)
             |> Enum.into(%{}, fn({k, v}) -> {k, v[service]} end)
           {service, %{cluster: test_service(service), nodes: service_node_configuration}}
         end)
    |> then(&({:ok, &1}))
  end


  def cached(node), do: configuration(node)
  def cached(), do: configuration()

  def cache(node, _), do: configuration(node)
  def cache(_), do: configuration()

  def lock_node(_node), do: {:ok, :ack}
  def release_node(_node), do: {:ok, :ack}
  def lock_node_service(_node, _service), do: {:ok, :ack}
  def release_node_service(_node, _service), do: {:ok, :ack}

  def report_cluster_health(_report), do: {:ok, :ack}
  def report_node_health(_node, _report), do: {:ok, :ack}
  def report_node_service_health(_node, _service, _report), do: {:ok, :ack}


end
