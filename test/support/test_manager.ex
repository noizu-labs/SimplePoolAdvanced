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
    Application.ensure_all_started(:syn)
    Application.ensure_all_started(:logger)
    Application.ensure_all_started(:noizu_advanced_pool)
    children = []
    opts = [strategy: :one_for_one, name: __MODULE__, strategy: :permanent,  max_restarts: 1_000_000, max_seconds: 1]
    Supervisor.start_link(children,opts)
  end

  def start_runner(context) do
    Application.ensure_all_started(:syn)
    Application.ensure_all_started(:logger)
    Application.ensure_all_started(:noizu_advanced_pool)
    ebs = %{id: :erl_boot_server, start: {:erl_boot_server, :start_link, [[]]}}
    children = [ebs]
    opts = [strategy: :one_for_one, name: __MODULE__, strategy: :permanent,  max_restarts: 1_000_000, max_seconds: 1]
    Supervisor.start_link(children,opts)
  end

  def add_service(spec) do
    Supervisor.start_child(__MODULE__, spec)
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
    wipe_error_logger()
    {:ok, _} = TS.add_service(CM.spec(context))
    {:ok, _} = TS.add_service(NM.spec(context))
  end

  def wipe_error_logger() do
    :error_logger.warning_msg("Halting :error_log for noisy syn messaging")
    :error_logger.limit_term(:error)
    Logger.configure(level: :warning)
    :ok
  end

  def member_start(caller, context) do
    wipe_error_logger()
    with {:ok, _} <- TS.start(context),
         :ok <- wipe_error_logger(),
         {:ok, _} <- TS.add_service(NM.spec(context)) do
      NM.bring_online(node(), context)|> Task.yield()
      send(caller, {node(), :ready})
      receive do
        :infinity -> :halt
      end
    else
      x ->
        send(caller, {node(), {:error, x}})
        x
    end
  end

  def bring_all_online(context) do
    h = Noizu.AdvancedPool.NodeManager.bring_online(node(), context)
    t = Enum.map(~w(a b c d e), fn(member) ->
      subordinate = :"nap_test_member_#{member}@localhost"
      Noizu.AdvancedPool.NodeManager.bring_online(subordinate, context)
    end)
    Task.yield_many([h | t])
  end

  def start_cluster(options, context) do
    if options[:epmd] == :tap do
    {"", 0} = System.cmd("epmd", ["-daemon"],[])
    end
    settings = "-setcookie #{Node.get_cookie()}" |> String.to_charlist()
    nap_config_manager = Application.get_env(:noizu_advanced_pool, :configuration)
    for member <- ~W(a b c d e) do
      subordinate = :"nap_test_member_#{member}"
      {:ok, _} = :slave.start(:localhost, subordinate, settings)
      :ok = :rpc.call(:"#{subordinate}@localhost", :code, :add_paths, [:code.get_path])
      :ok = :rpc.call(:"#{subordinate}@localhost",  Application, :put_env, [:noizu_advanced_pool, :configuration, nap_config_manager])
      :rpc.call(subordinate, __MODULE__, :wiper_error_log, [])
    end

    await_members = Task.async_stream(~w(a b c d e),
      fn(member) ->
        subordinate = :"nap_test_member_#{member}@localhost"
      :rpc.cast(subordinate, __MODULE__, :member_start, [self(), context])
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
