context = Noizu.ElixirCore.CallingContext.admin()
Logger.configure(level: :warn)
Application.ensure_all_started(:syn)
{:ok, _} = Noizu.AdvancedPool.Test.Supervisor.start()
{:ok, _} = Noizu.AdvancedPool.Test.Supervisor.add_service(Noizu.AdvancedPool.ClusterManager.spec(context))
{:ok, _} = Noizu.AdvancedPool.Test.Supervisor.add_service(Noizu.AdvancedPool.NodeManager.spec(context))

# Launch second node
IO.puts "Launching Second Node for Routing Tests"
Noizu.AdvancedPool.Test.NodeManager.start_node(:"second@127.0.0.1")

# Temporary Hack - current logic requires all nodes be aware of all other nodes, in the future we will add routing helpers
# To avoid the need to sync config across entire cluster.
# IO.puts BRING ONLINE?
#Process.sleep(5000)
Noizu.AdvancedPool.NodeManager.bring_online(node(), context) |> Task.yield()
Noizu.AdvancedPool.NodeManager.bring_online(:"second@127.0.0.1", context) |> Task.yield()

ExUnit.start(capture_log: true)