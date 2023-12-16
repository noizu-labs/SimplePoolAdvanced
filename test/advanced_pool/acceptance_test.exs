#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.AcceptanceTest do
  use ExUnit.Case, async: false
  require Logger
  require Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  require Noizu.AdvancedPool.NodeManager
  import Noizu.AdvancedPool.NodeManager
  import Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  def context(), do: Noizu.ElixirCore.CallingContext.system()

  describe "Cluster Manager" do
    test "health_report" do
      report = Noizu.AdvancedPool.ClusterManager.health_report(context())
      assert report == :pending_cluster_report
    end
    
    test "config" do
      cluster = Noizu.AdvancedPool.ClusterManager.configuration(context())
      tp = cluster[Noizu.AdvancedPool.Support.TestPool][:cluster]
      assert tp != nil
      assert cluster_service(tp, :state) == :online
      assert cluster_service(tp, :priority) == 1
    end

    test "status" do
      task = Noizu.AdvancedPool.NodeManager.bring_online(node(), context())
      Task.yield(task, :infinity)
      {:ok, nodes} = Noizu.AdvancedPool.ClusterManager.service_status(Noizu.AdvancedPool.Support.TestPool, context())
      {_pid, status} = nodes[node()]
      assert (pool_status(status, :health)) == 1.0
      # pending
    end
    
  end

  describe "Node Manager" do
    test "health_report" do
      report = Noizu.AdvancedPool.NodeManager.health_report(node(), context())
      assert report == :pending_node_report
      # pending
    end
  
    test "config" do
      node = Noizu.AdvancedPool.NodeManager.configuration(node(), context())
      tp = node[Noizu.AdvancedPool.Support.TestPool]
      assert tp != nil
      assert node_service(tp, :state) == :online
      assert node_service(tp, :priority) == 0
    end

    test "bring_online" do
      task = Noizu.AdvancedPool.NodeManager.bring_online(node(), context())
      {:ok, _} = Task.yield(task, :infinity)
      # pending
    end

    test "status" do
      task = Noizu.AdvancedPool.NodeManager.bring_online(node(), context())
      Task.yield(task, :infinity)
      {:ok, {_pid, status}} = Noizu.AdvancedPool.NodeManager.service_status(Noizu.AdvancedPool.Support.TestPool, node(), context())
      assert (pool_status(status, :health)) == :initializing
      # pending
    end
   
  end
  
  describe "Pool" do
    test "spawn workers" do
      task = Noizu.AdvancedPool.NodeManager.bring_online(node(), context())
      Task.yield(task, :infinity)

      r = Noizu.AdvancedPool.Support.TestPool.test(1,  context())
      assert r == 1
      Process.sleep(500)
      r = Noizu.AdvancedPool.Support.TestPool.test(1,  context())
      assert r == 2
      r = Noizu.AdvancedPool.Support.TestPool.test(2,  context())
      assert r == 1
      r = Noizu.AdvancedPool.Support.TestPool.test(1,  context())
      assert r == 3
    end

    test "direct link" do
      task = Noizu.AdvancedPool.NodeManager.bring_online(node(), context())
      Task.yield(task, :infinity)
  
      r = Noizu.AdvancedPool.Support.TestPool.test(5,  context())
      assert r == 1
      r = Noizu.AdvancedPool.Support.TestPool.test(5,  context())
      assert r == 2
      r = Noizu.AdvancedPool.Support.TestPool.test(6,  context())
      assert r == 1

      link = Noizu.AdvancedPool.Support.TestPool.get_direct_link!(5, context())
      
      r = Noizu.AdvancedPool.Support.TestPool.test(link,  context())
      assert r == 3

      r = Noizu.AdvancedPool.Support.TestPool.test(5,  context())
      assert r == 4
      
    end
    
    
    
  end
  
end
