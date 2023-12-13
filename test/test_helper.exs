
Application.ensure_all_started(:uuid)
context = Noizu.ElixirCore.CallingContext.system()
Noizu.AdvancedPool.Support.TestManager.runner_start([epmd: :tap], context)
Noizu.AdvancedPool.Support.TestManager.start_cluster([epmd: :tap], context)

ExUnit.start(capture_log: true)


IO.puts "---------------------------------------------------<"
