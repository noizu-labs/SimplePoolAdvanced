#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.ClusterManagerTest do
  use ExUnit.Case, async: false
  require Logger
  require Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  require Noizu.AdvancedPool.NodeManager
  import Noizu.AdvancedPool.NodeManager
  import Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  def context(), do: Noizu.ElixirCore.CallingContext.system()
  @moduletag :cluster_manager


  setup do
    on_exit(fn ->
      Noizu.AdvancedPool.ClusterManager.release_pool(Noizu.AdvancedPool.Support.TestPool, node(), context())
    end)
  end

  describe "cluster status" do
    @describetag cluster_manager: :status

    test "service status - on master node" do
      records = Noizu.AdvancedPool.ClusterManager.service_status_records(Noizu.AdvancedPool.Support.TestPool, context())
      with [{_, pool_status(status: :online, service: Noizu.AdvancedPool.Support.TestPool, node: :"nap_test_runner@localhost")}] <- records do
        :ok
        else
          [{_, pool_status() = error}] ->
          assert error == pool_status(error, status: :online, service: Noizu.AdvancedPool.Support.TestPool, node: :"nap_test_runner@localhost")
          error ->
          assert error == :expected_pool_status
      end
    end

    test "service status" do
      records = Noizu.AdvancedPool.ClusterManager.service_status_records(Noizu.AdvancedPool.Support.TestPool2, context())
      assert length(records) == 6
      online = Enum.filter(records, & pool_status(elem(&1, 1), :status) == :online)
      assert length(online) == 6
    end

    test "service worker supervisor status" do
      records = Noizu.AdvancedPool.ClusterManager.pool_worker_supervisors(Noizu.AdvancedPool.Support.TestPool2, node(), context())
      with [{_, worker_sup_status(status: :online, service: Noizu.AdvancedPool.Support.TestPool2, node: :"nap_test_runner@localhost")}] <- records do
        :ok
        else
          [{_, worker_sup_status() = error}] ->
          assert error == worker_sup_status(error, status: :online, service: Noizu.AdvancedPool.Support.TestPool2, node: :"nap_test_runner@localhost")
          error ->
          assert error == :expected_worker_supervisor_status
      end
    end

  end

  describe "node picker" do
    @describetag cluster_manager: :node_picker


    test "pick node" do
      # pool, ref, settings, context, options
      {:ok, n} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool, ref(module: Noizu.AdvancedPool.Support.TestPool.Worker, identifier: 555), settings(), context())
      assert n == node()
      {:ok, n} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool2, ref(module: Noizu.AdvancedPool.Support.TestPool.Worker, identifier: 556), settings(), context())
      assert n in Noizu.AdvancedPool.Support.TestManager.members()
    end

    @tag capture_log: false
    test "pick node - with saturation" do
      # Note this test is temporary and relied on the fact that health checks do not currently automatically update and the ability to force a health check refresh.
      # However only minor alterations will be needed once they do automatically refresh. To wait on health_report to complete before proceeding with pick node asserts and sticky threshold updated to correct value.


      # pool, ref, settings, context, options
      {_, host, _} = Noizu.AdvancedPool.Support.TestPool4.fetch(6555 + 0, :process, context())
      {_, host, _} = Noizu.AdvancedPool.Support.TestPool4.fetch(6555 + 1, :process, context())
      {_, host, _} = Noizu.AdvancedPool.Support.TestPool4.fetch(6555 + 2, :process, context())
      Noizu.AdvancedPool.ClusterManager.health_report(context())
      Process.sleep(500)
      {:ok, n} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 20), settings(sticky?: 0.3), context())
      assert n == node()
      for i <- 3..19 do
        {_, host, _} = Noizu.AdvancedPool.Support.TestPool4.fetch(6555 + i, :process, context())
      end
      Process.sleep(500)
      Noizu.AdvancedPool.ClusterManager.health_report(context())
      {:ok, n1} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 22), settings(sticky?: 0.3), context())
      {:ok, n2} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 23), settings(sticky?: 0.3), context())
      {:ok, n3} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 24), settings(sticky?: 0.3), context())
      {:ok, n4} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 25), settings(sticky?: 0.3), context())
      {:ok, n5} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 26), settings(sticky?: 0.3), context())
      {:ok, n6} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 27), settings(sticky?: 0.3), context())
      assert (([n1,n2,n3,n4,n5,n6] |> Enum.uniq()) -- [node()]) |> List.first() == nil
      Process.sleep(500)
      {:ok, n1} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 22), settings(sticky?: 0.3), context())
      {:ok, n2} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 23), settings(sticky?: 0.3), context())
      {:ok, n3} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 24), settings(sticky?: 0.3), context())
      {:ok, n4} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 25), settings(sticky?: 0.3), context())
      {:ok, n5} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 26), settings(sticky?: 0.3), context())
      {:ok, n6} = Noizu.AdvancedPool.ClusterManager.pick_node(Noizu.AdvancedPool.Support.TestPool4, ref(module: Noizu.AdvancedPool.Support.TestPool4.Worker, identifier: 6555 + 27), settings(sticky?: 0.3), context())
      assert (([n1,n2,n3,n4,n5,n6] |> Enum.uniq()) -- [node()]) |> List.first() != nil

    end

  end


  describe "cluster management" do
    @describetag cluster_manager: :management


    test "Lock Service" do
      Noizu.AdvancedPool.ClusterManager.lock_pool(Noizu.AdvancedPool.Support.TestPool, :"nap_test_runner@localhost", context())
      records = Noizu.AdvancedPool.ClusterManager.service_status_records(Noizu.AdvancedPool.Support.TestPool, context())
      with [{_, pool_status(status: {:locked, :online}, service: Noizu.AdvancedPool.Support.TestPool, node: :"nap_test_runner@localhost")}] <- records do
        :ok
      else
        [{_, pool_status() = error}] ->
          assert error == pool_status(error, status: {:locked, :online}, service: Noizu.AdvancedPool.Support.TestPool, node: :"nap_test_runner@localhost")
        error ->
          assert error == :expected_pool_status
      end

      {:error, :unavailable} = Noizu.AdvancedPool.Support.TestPool.fetch(11321, :process, context())
      Noizu.AdvancedPool.ClusterManager.release_pool(Noizu.AdvancedPool.Support.TestPool, :"nap_test_runner@localhost", context())
      {_, host, _} = Noizu.AdvancedPool.Support.TestPool.fetch(11321, :process, context())
      assert host == node()

      Noizu.AdvancedPool.ClusterManager.lock_pool(Noizu.AdvancedPool.Support.TestPool, :"nap_test_runner@localhost", context())
      {:error, :unavailable} = Noizu.AdvancedPool.Support.TestPool.fetch(11322, :process, context())
      {_, host, _} = Noizu.AdvancedPool.Support.TestPool.fetch(11321, :process, context())
      assert host == node()

    end

  end

end
