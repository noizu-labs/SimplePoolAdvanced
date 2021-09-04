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

alias Noizu.SimplePoolAdvancedAdvanced.Support.TestPool
alias Noizu.SimplePoolAdvancedAdvanced.Support.TestTwoPool
#alias Noizu.SimplePoolAdvancedAdvanced.Support.TestThreePool
Application.ensure_all_started(:bypass)
Application.ensure_all_started(:semaphore)



#-----------------------------------------------
# Test Schema Setup
#-----------------------------------------------
Amnesia.start

#-------------------------
# V3 Core Tables
#-------------------------
if !Amnesia.Table.exists?(Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.Setting.Table) do
  :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.Setting.Table.create()
  :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.Configuration.Table.create()
  :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.Node.Table.create()
  :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.Service.Table.create()


  :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.ServiceEvent.Table.create()
  :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.ServerEvent.Table.create()
  :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.ClusterEvent.Table.create()
end

  Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.DetailedServiceEvent.Table.create()
  Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.DetailedServerEvent.Table.create()

  Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.DetailedServiceEvent.Table.add_copy(node(), :memory)
  Noizu.SimplePoolAdvancedAdvanced.V3.Database.MonitoringFramework.DetailedServerEvent.Table.add_copy(node(), :memory)

#-------------------------
# V3.B Core Tables
#-------------------------
if !Amnesia.Table.exists?(Noizu.SimplePoolAdvancedAdvanced.V3.Database.Cluster.Service.Instance.State.Table) do
  IO.puts "SETUP V3.B Tables"
  if (node() == :"first@127.0.0.1") do
    :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.Cluster.Setting.Table.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.Cluster.State.Table.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.Cluster.Task.Table.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.Cluster.Service.State.Table.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.Cluster.Service.Worker.Table.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.Cluster.Service.Task.Table.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.Cluster.Service.Instance.State.Table.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.Cluster.Node.State.Table.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.Cluster.Node.Worker.Table.create(memory: [:"first@127.0.0.1"])
    :ok = Noizu.SimplePoolAdvancedAdvanced.V3.Database.Cluster.Node.Task.Table.create(memory: [:"first@127.0.0.1"])
  end

end




#---------------------
# Test Pool: Dispatch Tables
#---------------------
if !Amnesia.Table.exists?(Noizu.SimplePoolAdvancedAdvanced.TestDatabase.TestV3Pool.Dispatch.Table) do
  :ok = Noizu.SimplePoolAdvancedAdvanced.TestDatabase.TestV3Pool.Dispatch.Table.create()
end
if !Amnesia.Table.exists?(Noizu.SimplePoolAdvancedAdvanced.TestDatabase.TestV3TwoPool.Dispatch.Table) do
  :ok = Noizu.SimplePoolAdvancedAdvanced.TestDatabase.TestV3TwoPool.Dispatch.Table.create()
end
if !Amnesia.Table.exists?(Noizu.SimplePoolAdvancedAdvanced.TestDatabase.TestV3ThreePool.Dispatch.Table) do
  :ok = Noizu.SimplePoolAdvancedAdvanced.TestDatabase.TestV3ThreePool.Dispatch.Table.create()
end


:ok = Amnesia.Table.wait(Noizu.SimplePoolAdvancedAdvanced.V3.Database.tables(), 5_000)
:ok = Amnesia.Table.wait(Noizu.SimplePoolAdvancedAdvanced.TestDatabase.tables(), 5_000)

# Wait for second node
connected = Node.connect(:"second@127.0.0.1")
if (!connected) do
  IO.puts "Waiting five minutes for second test node (./test-node.sh)"
  case Noizu.SimplePoolAdvancedAdvanced.TestHelpers.wait_for_condition(fn() -> (Node.connect(:"second@127.0.0.1") == true) end, 60 * 5) do
    :ok ->
      IO.puts "Second Node Online"
    {:error, :timeout} ->
      IO.puts "Timeout Occurred waiting for Second Node"
      exit(:shutdown)
  end
end

# Wait for connectivity / compile
Noizu.SimplePoolAdvancedAdvanced.TestHelpers.wait_for_condition(
  fn() ->
    :rpc.call(:"second@127.0.0.1", Noizu.SimplePoolAdvancedAdvanced.TestHelpers, :wait_for_init, []) == :ok
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

:ok = :rpc.call(:"second@127.0.0.1", Noizu.SimplePoolAdvancedAdvanced.TestHelpers, :wait_for_db, [])

#-----------------------------------------------
# Registry and Environment Manager Setup - Local
#-----------------------------------------------
context = Noizu.ElixirCore.CallingContext.system(%{})
Noizu.SimplePoolAdvancedAdvanced.TestHelpers.setup_first()

if spawn_second do
  IO.puts "Provision Second Node for Test"
  {:pid, _second_pid} = :rpc.call(:"second@127.0.0.1", Noizu.SimplePoolAdvancedAdvanced.TestHelpers, :setup_second, [])
else
  IO.puts "Checking second node state"
  case :rpc.call(:"second@127.0.0.1", Noizu.SimplePoolAdvancedAdvanced.V3.ClusterManagementFramework.ClusterManager, :node_health_check!, [context, %{}]) do
    {:badrpc, _} ->
      {:pid, _second_pid} = :rpc.call(:"second@127.0.0.1", Noizu.SimplePoolAdvancedAdvanced.TestHelpers, :setup_second, [])
    v -> IO.puts "Checking second node state #{inspect v}"
  end
end

if (node() == :"first@127.0.0.1") do
  IO.puts "//////////////////////////////////////////////////////"
  IO.puts "waiting for TestV3Two to come online"
  IO.puts "//////////////////////////////////////////////////////"
  # Wait for connectivity / compile
  Noizu.SimplePoolAdvancedAdvanced.TestHelpers.wait_for_condition(
    fn() ->
      :rpc.call(:"second@127.0.0.1", Noizu.SimplePoolAdvancedAdvanced.Support.TestV3TwoPool.Server, :server_online?, []) == true
    end,
    60 * 5
  )

  IO.puts "//////////////////////////////////////////////////////"
  IO.puts "waiting for remote registry"
  IO.puts "//////////////////////////////////////////////////////"

  :ok = Noizu.SimplePoolAdvanced.TestHelpers.wait_for_condition(
    fn() ->
      :rpc.call(:"second@127.0.0.1", Registry, :lookup, [Noizu.SimplePoolAdvanced.Support.TestV3TwoPool.Registry, {:worker, :aple}]) == []
    end,
    60 * 5
  )
  [] = :rpc.call(:"second@127.0.0.1", Registry, :lookup, [Noizu.SimplePoolAdvanced.Support.TestV3TwoPool.Registry, {:worker, :aple}])



  IO.puts "//////////////////////////////////////////////////////"
  IO.puts "Proceed"
  IO.puts "//////////////////////////////////////////////////////"

end
