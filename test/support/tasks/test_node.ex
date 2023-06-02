defmodule Mix.Tasks.TestNode do
  use Mix.Task
  @shortdoc "Test Node Entry Point for MultiNode Testing"
  def run([host]) do
    IO.puts("Running...")
    Logger.configure(level: :error)
    Application.ensure_all_started(:syn)
    Application.ensure_all_started(:logger)
    Application.ensure_all_started(:noizu_advanced_pool)
    context = Noizu.ElixirCore.CallingContext.system()
    {:ok, _} = Noizu.AdvancedPool.Test.Supervisor.start()
    {:ok, _} = Noizu.AdvancedPool.Test.Supervisor.add_service(Noizu.AdvancedPool.NodeManager.spec(context))

    #Noizu.AdvancedPool.NodeManager.bring_online(node(), context)
    do_wait(String.to_atom(host))
  end

  def do_wait(host, attempts \\ 0) do
    with :pong <- Node.ping(host) do
      Process.sleep(100)
      do_wait(host, 0)
    else
      _ ->
        unless attempts > 4 do
          Process.sleep(100)
          do_wait(host, attempts + 1)
        end
    end
  end
end