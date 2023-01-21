context = Noizu.ElixirCore.CallingContext.admin()
Application.ensure_all_started(:syn)
{:ok, _} = Noizu.AdvancedPool.Test.Supervisor.start()
{:ok, _} = Noizu.AdvancedPool.Test.Supervisor.add_service(Noizu.AdvancedPool.ClusterManager.spec(context))
{:ok, _} = Noizu.AdvancedPool.Test.Supervisor.add_service(Noizu.AdvancedPool.NodeManager.spec(context))
{:ok, _} = Noizu.AdvancedPool.Test.Supervisor.add_service(Noizu.AdvancedPool.Support.TestPool.pool_spec(context))

c = Supervisor.which_children(Noizu.AdvancedPool.Support.TestPool)
Noizu.AdvancedPool.WorkerSupervisor.refresh_pool_status(  Enum.at(c, 0) |> elem(1) , Noizu.AdvancedPool.Support.TestPool)
:syn.members(Noizu.AdvancedPool.Support.TestPool, :nodes)

Noizu.AdvancedPool.Support.TestPool.add_worker(context, [], false)
Noizu.AdvancedPool.Support.TestPool.add_worker(context, [], true)

:syn.members(Noizu.AdvancedPool.Support.TestPool, :nodes)
:syn.members(Noizu.AdvancedPool.Support.TestPool, {node(), :worker_supervisor})
:pending_cluster_report = Noizu.AdvancedPool.ClusterManager.health_report(context)
:pending_node_report = Noizu.AdvancedPool.NodeManager.health_report(node(), context)
{:nack, :not_registered} = Noizu.AdvancedPool.NodeManager.health_report(:not_valid, context)

# Noizu.AdvancedPool.NodeManager.health_report(context)
# GenServer.call(Noizu.AdvancedPool.Support.TestPool.Server, :Apple)
# Noizu.AdvancedPool.Message.Dispatch.s_call({:ref, Noizu.AdvancedPool.Support.TestPool.Server, 1234}, :hello, context)
ExUnit.start()