defmodule Noizu.AdvancedPool.Test.Supervisor do
  use Supervisor
  require Logger


  def terminate(reason, state) do
    Logger.warning("""
    TERMINATE #{__MODULE__}#{inspect __ENV__.function}
    ***************************************
    #{inspect({reason, state})}
    """)
    :ok
  end

  def start(context) do
    log_level = Logger.configure(level: :warn)
    :error_logger.stop()
    Application.ensure_all_started(:syn)
    :error_logger.stop()
    Application.ensure_all_started(:logger)
    Application.ensure_all_started(:noizu_advanced_pool)
    children = []
    opts = [strategy: :one_for_one, name: __MODULE__, strategy: :permanent,  max_restarts: 1_000_000, max_seconds: 1]
    #opts = [strategy: :permanent, max_restarts: 1_000_000, max_seconds: 1]
    #opts = [strategy: :one_for_one, name: __MODULE__, strategy: :permanent]
    Supervisor.start_link(children,opts)
    |> tap(fn(_) -> Logger.configure(level: log_level) end)
    |> tap(&
    Logger.warn("""
    ===============[ start standard ]=====================
    #{inspect &1}
    ======================================
    ======================================
    """))
  end

  def start_runner(context) do
    log_level = Logger.configure(level: :warn)
    :error_logger.stop()
    Application.ensure_all_started(:syn)
    :error_logger.stop()
    Application.ensure_all_started(:logger)
    Application.ensure_all_started(:noizu_advanced_pool)
    ebs = %{id: :erl_boot_server, start: {:erl_boot_server, :start_link, [[]]}}
    children = [ebs]
    children = []
    #opts = [strategy: :one_for_one, name: __MODULE__, strategy: :permanent]
    opts = [strategy: :one_for_one, name: __MODULE__, strategy: :permanent,  max_restarts: 1_000_000, max_seconds: 1]
    Supervisor.start_link(children,opts)
    |> tap(fn(_) -> Logger.configure(level: log_level) end)
    |> IO.inspect(label: "Test Supervisor Runner Start")
  end

  def add_service(spec) do
    Supervisor.start_child(__MODULE__, spec)
    |> tap(& IO.inspect({&1, spec}, label: "Test Supervisor Add Service"))
  end
end

defmodule Noizu.AdvancedPool.Support.TestManager do
  alias Noizu.AdvancedPool.Test.Supervisor, as: TS
  alias Noizu.AdvancedPool.ClusterManager, as: CM
  alias Noizu.AdvancedPool.NodeManager, as: NM
  require Logger
  def runner_start(options, context) do
    if options[:epmd] == :tap do
      {"", 0} = System.cmd("epmd", ["-daemon"],[])
    end
    Application.put_env(:noizu_advanced_pool, :is_test_runner, [true])
    {:ok, _} = Node.start(:nap_test_runner@localhost, :shortnames)
    TS.start_runner(context)
    {:ok, _} = TS.add_service(CM.spec(context))
    {:ok, _} = TS.add_service(NM.spec(context))
  end

  def member_start(caller, context) do
    with {:ok, _} <- TS.start(context),
         {:ok, _} <- TS.add_service(NM.spec(context)) do
      NM.bring_online(node(), context)|> Task.yield()
      send(caller, {node(), :ready})

      IO.puts "END START"
      receive do
        :infinity -> :halt
      end
      IO.puts "END END START"

    else
      x ->
        send(caller, {node(), {:error, x}})
        x
    end
  end

  def start_cluster(options, context) do
    if options[:epmd] == :tap do
    {"", 0} = System.cmd("epmd", ["-daemon"],[])
    end
    settings = "-setcookie #{Node.get_cookie()}" |> String.to_charlist()
    nap_config_manager = Application.get_env(:noizu_advanced_pool, :configuration)
    for member <- ~W(a ) do
      subordinate = :"nap_test_member_#{member}"
      {:ok, _} = :slave.start(:localhost, subordinate, settings)
      :ok = :rpc.call(:"#{subordinate}@localhost", :code, :add_paths, [:code.get_path])
      :ok = :rpc.call(:"#{subordinate}@localhost",  Application, :put_env, [:noizu_advanced_pool, :configuration, nap_config_manager])
    end

    await_members = Task.async_stream(~w(a ),
      fn(member) ->
        subordinate = :"nap_test_member_#{member}@localhost"
      :ok = :rpc.call(subordinate, __MODULE__, :member_start, [self(), context])
      receive do
        {subordinate, :ready} -> :ok
        {subordinate, {:error, x}} -> {:error, x}
        after 15000 ->
          Logger.warning("#{subordinate} start delay . . .")
          receive do
            {subordinate, :ready} -> {subordinate, :ready}
            {subordinate, {:error, x}} -> {:error, x}
          end
      end
    end, timeout: :infinity)

    bring_online = NM.bring_online(node(), context)

    ns = bring_online
         |> Task.yield(15_000)
         |> then(
              fn
                nil ->
                  Logger.error("#{node()} start delay . . .")
                  Task.yield(bring_online)
                x -> x
              end)
    ms = await_members
    |> Enum.to_list()
    {:ok, [ns | ms]}
  end

end
