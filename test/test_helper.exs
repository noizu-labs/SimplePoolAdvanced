#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

require Logger
Logger.info """

  ----------------------------------
  Test Start
  ----------------------------------
"""
ExUnit.start()

alias Noizu.SimplePool.Support.TestPool
alias Noizu.SimplePool.Support.TestTwoPool
#alias Noizu.SimplePool.Support.TestThreePool
Application.ensure_all_started(:bypass)
Application.ensure_all_started(:semaphore)



#-----------------------------------------------
# Test Schema Setup
#-----------------------------------------------
Amnesia.start

#-------------------------
# V3 Core Tables
#-------------------------
if !Amnesia.Table.exists?(Noizu.SimplePool.V3.Database.MonitoringFramework.SettingTable) do
  :ok = Noizu.SimplePool.V3.Database.MonitoringFramework.SettingTable.create()
  :ok = Noizu.SimplePool.V3.Database.MonitoringFramework.ConfigurationTable.create()
  :ok = Noizu.SimplePool.V3.Database.MonitoringFramework.NodeTable.create()
  :ok = Noizu.SimplePool.V3.Database.MonitoringFramework.ServiceTable.create()


  :ok = Noizu.SimplePool.V3.Database.MonitoringFramework.ServiceEventTable.create()
  :ok = Noizu.SimplePool.V3.Database.MonitoringFramework.ServerEventTable.create()
  :ok = Noizu.SimplePool.V3.Database.MonitoringFramework.ClusterEventTable.create()
end

  Noizu.SimplePool.V3.Database.MonitoringFramework.DetailedServiceEventTable.create()
  Noizu.SimplePool.V3.Database.MonitoringFramework.DetailedServerEventTable.create()

  Noizu.SimplePool.V3.Database.MonitoringFramework.DetailedServiceEventTable.add_copy(node(), :memory)
  Noizu.SimplePool.V3.Database.MonitoringFramework.DetailedServerEventTable.add_copy(node(), :memory)

#-------------------------
# V3.B Core Tables
#-------------------------
if !Amnesia.Table.exists?(Noizu.SimplePool.V3.Database.Cluster.Service.Instance.StateTable) do
  IO.puts "SETUP V3.B Tables"
  if (node() == :"first@127.0.0.1") do
    :ok = Noizu.SimplePool.V3.Database.Cluster.SettingTable.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePool.V3.Database.Cluster.StateTable.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePool.V3.Database.Cluster.TaskTable.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePool.V3.Database.Cluster.Service.StateTable.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePool.V3.Database.Cluster.Service.WorkerTable.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePool.V3.Database.Cluster.Service.TaskTable.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePool.V3.Database.Cluster.Service.Instance.StateTable.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePool.V3.Database.Cluster.Node.StateTable.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePool.V3.Database.Cluster.Node.WorkerTable.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePool.V3.Database.Cluster.Node.TaskTable.create(memory: [:"first@127.0.0.1"])
  end

end




#---------------------
# Test Pool: Dispatch Tables
#---------------------
if !Amnesia.Table.exists?(Noizu.SimplePool.TestDatabase.TestV3Pool.DispatchTable) do
  :ok = Noizu.SimplePool.TestDatabase.TestV3Pool.DispatchTable.create()
end
if !Amnesia.Table.exists?(Noizu.SimplePool.TestDatabase.TestV3TwoPool.DispatchTable) do
  :ok = Noizu.SimplePool.TestDatabase.TestV3TwoPool.DispatchTable.create()
end
if !Amnesia.Table.exists?(Noizu.SimplePool.TestDatabase.TestV3ThreePool.DispatchTable) do
  :ok = Noizu.SimplePool.TestDatabase.TestV3ThreePool.DispatchTable.create()
end


:ok = Amnesia.Table.wait(Noizu.SimplePool.V3.Database.tables(), 5_000)
:ok = Amnesia.Table.wait(Noizu.SimplePool.TestDatabase.tables(), 5_000)

# Wait for second node
connected = Node.connect(:"second@127.0.0.1")
if (!connected) do
  IO.puts "Waiting five minutes for second test node (./test-node.sh)"
  case Noizu.SimplePool.TestHelpers.wait_for_condition(fn() -> (Node.connect(:"second@127.0.0.1") == true) end, 60 * 5) do
    :ok ->
      IO.puts "Second Node Online"
    {:error, :timeout} ->
      IO.puts "Timeout Occurred waiting for Second Node"
      exit(:shutdown)
  end
end

# Wait for connectivity / compile
Noizu.SimplePool.TestHelpers.wait_for_condition(
  fn() ->
    :rpc.call(:"second@127.0.0.1", Noizu.SimplePool.TestHelpers, :wait_for_init, []) == :ok
  end,
  60 * 5
)

spawn_second = if !Enum.member?(Amnesia.info(:db_nodes),:"second@127.0.0.1") do
    # conditional include to reduce the need to restart the remote server
    IO.puts "SPAWN SECOND == true"
    :mnesia.change_config(:extra_db_nodes, [:"second@127.0.0.1"])
    true
  else
    IO.puts "SPAWN SECOND == false"
    false
  end

:ok = :rpc.call(:"second@127.0.0.1", Noizu.SimplePool.TestHelpers, :wait_for_db, [])

#-----------------------------------------------
# Registry and Environment Manager Setup - Local
#-----------------------------------------------
context = Noizu.ElixirCore.CallingContext.system(%{})
Noizu.SimplePool.TestHelpers.setup_first()

if spawn_second do
  IO.puts "Provision Second Node for Test"
  {:pid, _second_pid} = :rpc.call(:"second@127.0.0.1", Noizu.SimplePool.TestHelpers, :setup_second, [])
else
  IO.puts "Checking second node state"
  case :rpc.call(:"second@127.0.0.1", Noizu.SimplePool.V3.ClusterManagementFramework.ClusterManager, :node_health_check!, [context, %{}]) do
    {:badrpc, _} ->
      {:pid, _second_pid} = :rpc.call(:"second@127.0.0.1", Noizu.SimplePool.TestHelpers, :setup_second, [])
    v -> IO.puts "Checking second node state #{inspect v}"
  end
end

if (node() == :"first@127.0.0.1") do
  IO.puts "//////////////////////////////////////////////////////"
  IO.puts "waiting for TestV3Two to come online"
  IO.puts "//////////////////////////////////////////////////////"
  # Wait for connectivity / compile
  Noizu.SimplePool.TestHelpers.wait_for_condition(
    fn() ->
      :rpc.call(:"second@127.0.0.1", Noizu.SimplePool.Support.TestV3TwoPool.Server, :server_online?, []) == true
    end,
    60 * 5
  )

  IO.puts "//////////////////////////////////////////////////////"
  IO.puts "waiting for remote registry"
  IO.puts "//////////////////////////////////////////////////////"

  :ok = Noizu.SimplePool.TestHelpers.wait_for_condition(
    fn() ->
      :rpc.call(:"second@127.0.0.1", Registry, :lookup, [Noizu.SimplePool.Support.TestV3TwoPool.Registry, {:worker, :aple}]) == []
    end,
    60 * 5
  )
  [] = :rpc.call(:"second@127.0.0.1", Registry, :lookup, [Noizu.SimplePool.Support.TestV3TwoPool.Registry, {:worker, :aple}])



  IO.puts "//////////////////////////////////////////////////////"
  IO.puts "Proceed"
  IO.puts "//////////////////////////////////////////////////////"

end
