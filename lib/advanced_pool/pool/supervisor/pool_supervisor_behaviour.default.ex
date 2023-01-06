#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.PoolSupervisorBehaviour.Default do
  alias Noizu.ElixirCore.OptionSettings
  alias Noizu.ElixirCore.OptionValue
  alias Noizu.ElixirCore.OptionList
  require Logger

  @features ([:auto_load, :auto_identifier, :lazy_load, :async_load, :inactivity_check, :s_redirect, :s_redirect_handle, :ref_lookup_cache, :call_forwarding, :graceful_stop, :crash_protection])
  @default_features ([:auto_load, :lazy_load, :s_redirect, :s_redirect_handle, :inactivity_check, :call_forwarding, :graceful_stop, :crash_protection])

  @default_max_seconds (1)
  @default_max_restarts (1_000_000)
  @default_strategy (:one_for_one)

  #------------
  #
  #------------
  def prepare_options_slim(options), do: Noizu.ElixirCore.SlimOptions.slim(prepare_options(options))
  def prepare_options(options) do
    settings = %OptionSettings{
      option_settings: %{
        features: %OptionList{option: :features, default: Application.get_env(:noizu_advanced_pool, :default_features, @default_features), valid_members: @features, membership_set: false},
        verbose: %OptionValue{option: :verbose, default: :auto},
        max_restarts: %OptionValue{option: :max_restarts, default: Application.get_env(:noizu_advanced_pool, :pool_max_restarts, @default_max_restarts)},
        max_seconds: %OptionValue{option: :max_seconds, default: Application.get_env(:noizu_advanced_pool, :pool_max_seconds, @default_max_seconds)},
        strategy: %OptionValue{option: :strategy, default: Application.get_env(:noizu_advanced_pool, :pool_strategy, @default_strategy)}
      }
    }

    OptionSettings.expand(settings, options)
  end

  def skinny_banner(mod, contents), do: "[#{mod.base()}:PoolSupervisor}] #{inspect self()} - #{contents}"


  #------------
  #
  #------------
  def start_link(module, definition \\ :auto, context \\ nil) do
    module.verbose() && Logger.info(fn -> {skinny_banner(module, "start_link(#{inspect definition, limit: 10})"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
    case Supervisor.start_link(module, [definition, context], [{:name, module}, {:restart, :permanent}, {:shutdown, :infinity}]) do
      {:ok, sup} ->
        module.verbose() && Logger.info(fn -> {skinny_banner(module, "start_link Supervisor Initial Start. #{inspect sup}"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
        #module.start_children(sup, definition, context)
        {:ok, sup}
      {:error, {:already_started, sup}} ->
        module.verbose() && Logger.warn(fn -> {skinny_banner(module, "start_link Supervisor Already Started. Handling Unexpected State. #{inspect sup}"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
        #module.start_children(sup, definition, context)
        {:ok, sup}
      {:error, {{:already_started, sup}, e}} ->
        module.verbose() && Logger.error(fn -> {skinny_banner(module, "start_link Supervisor Already Started. Handling Unexpected State. #{inspect sup}:#{inspect e}"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
        #module.start_children(sup, definition, context)
        {:ok, sup}
    end
  end

  def add_child_supervisor(module, child, definition \\ :auto, context \\ nil) do
    #max_seconds = module.meta()[:max_seconds]
    #max_restarts = module.meta()[:max_restarts]

    case Supervisor.start_child(module, module.pass_through_supervisor(child, [definition, context],  [restart: :permanent])) do
      {:ok, pid} ->
        {:ok, pid}
      error = {:error, {:already_started, process2_id}} ->
        r = Supervisor.restart_child(module, process2_id)
        Logger.warn(fn ->
          {
            """

            #{module}.add_child_supervisor #{inspect child} Already Started. Handling unexpected state.
            #{inspect error} -> restart_child: #{inspect r}
            """, Noizu.ElixirCore.CallingContext.metadata(context)}
        end)
        r
      error ->
        Logger.error(fn ->
          {
            """

            #{module}.add_child_supervisor #{inspect child} Already Started. Handling unexpected state.
            #{inspect error}
            """, Noizu.ElixirCore.CallingContext.metadata(context)}
        end)
        :error
    end
  end

  def add_child_worker(module, child, definition \\ :auto, context \\ nil) do
    #max_seconds = module.meta()[:max_seconds]
    #max_restarts = module.meta()[:max_restarts]

    case Supervisor.start_child(module, module.pass_through_worker(child, [definition, context],  [restart: :permanent])) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, process2_id}} ->
        Supervisor.restart_child(module, process2_id)
      error ->
        Logger.error(fn ->
          {
            """

            #{module}.add_child_worker #{inspect child} Already Started. Handling unexpected state.
            #{inspect error}
            """, Noizu.ElixirCore.CallingContext.metadata(context)}
        end)
        :error
    end
  end

  #------------
  #
  #------------
  def start_children(module, sup, definition \\ :auto, context \\ nil) do
    
    start_task_supervisor(module, sup, context)
    
    stand_alone = module.pool().stand_alone()
    registry_process = cond do
                         stand_alone -> {:ok, :offline}
                         !stand_alone -> start_registry_child(module, sup, context)
                       end
    worker_supervisor_process = cond do
                                  stand_alone -> {:ok, :offline}
                                  !stand_alone -> start_worker_supervisor_child(module, sup, definition, context)
                                end
    server_process = start_server_child(module, sup, definition, context)
    monitor_process = start_monitor_child(module, sup, server_process, definition, context)

    #------------------
    # start server initialization process.
    #------------------
    if server_process != :error && module.auto_load(), do: spawn fn -> module.pool_server().load_pool(context) end

    #------------------
    # Response
    #------------------
    outcome = cond do
                server_process == :error || Kernel.match?({:error, _}, server_process) -> :error
                monitor_process == :error || Kernel.match?({:error, _}, monitor_process) -> :error
                worker_supervisor_process == :error || Kernel.match?({:error, _}, worker_supervisor_process) -> :error
                registry_process == :error || Kernel.match?({:error, _}, registry_process) -> :error
                true -> :ok
              end


    # Return children
    children_processes = %{
      worker_supervisor_process: worker_supervisor_process,
      monitor_process: monitor_process,
      server_process: server_process,
      registry_process: registry_process
    }

    if module.verbose() do
      Logger.debug(fn ->
        {
          module.banner("#{module}.start_children",
            """
             sup: #{inspect sup}
             -------
             children_processes: #{inspect children_processes}
             -------
             outcome: #{inspect outcome}
            """),
          Noizu.ElixirCore.CallingContext.metadata(context)
        } end)
    end

    {outcome, children_processes}
  end # end start_children

  def init(module, [definition, context] = arg) do
    if module.verbose() do
      Logger.info(fn -> {module.banner("#{module} INIT", "args: #{inspect definition}"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
    end
    strategy = module.meta()[:strategy]
    max_seconds = module.meta()[:max_seconds]
    max_restarts = module.meta()[:max_restarts]
    stand_alone = module.pool().stand_alone()
    
    children = cond do
                 stand_alone -> []
                 !stand_alone ->
                   # Registry
                   registry_options = (module.pool().options()[:registry_options] || [])
                                      |> put_in([:name], module.__registry__())
                                      |> update_in([:keys], &(&1 || :unique))
                                      |> update_in([:partitions], &(&1 || 256)) # @TODO - processor count * 4
                   registry_child = Registry.child_spec(registry_options)

                   # Worker Supervisor
                   worker_supervisor_child = module.pass_through_supervisor(module.__worker_supervisor__(), [definition, context],  [shutdown: :infinity, restart: :permanent])
                   [registry_child, worker_supervisor_child]
               end
    children = [task_supervisor_spec(module, context)] ++ children ++ [
      module.pass_through_worker(module.pool_server(), [definition, context], [shutdown: :infinity, restart: :permanent]),
      module.pass_through_worker(module.pool_monitor(), [{module.pool_server(), node()}, definition, context], [shutdown: :infinity, restart: :permanent])
    ] |> IO.inspect(label: "MODULE CHILDREN| #{module}")
    module.pass_through_supervise(children, [{:strategy, strategy}, {:max_restarts, max_restarts}, {:max_seconds, max_seconds}, {:restart, :permanent}], [verbose: true])
  end
  
  def task_supervisor_spec(module, _) do
    module.pass_through_supervisor(Task.Supervisor, [[name: module.__task_supervisor__()]], [id: module.__task_supervisor__()])
  end
  
  defp start_registry_child(module, sup, context) do
    registry_options = (module.pool().options()[:registry_options] || [])
                       |> put_in([:name], module.__registry__())
                       |> update_in([:keys], &(&1 || :unique))
                       |> update_in([:partitions], &(&1 || 256)) # @TODO - processor count * 4


    #max_seconds = module.meta()[:max_seconds]
    #max_restarts = module.meta()[:max_restarts]
    #Registry.start_link(keys: :unique, name: GoldenRatio.Dispatch.AlertRegistry,  partitions: 256)
    # module.pass_through_worker(Registry, registry_options,  [restart: :permanent, max_restarts: max_restarts, max_seconds: max_seconds])
    case Supervisor.start_child(sup,  Registry.child_spec(registry_options)) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, process2_id}} ->
        case Supervisor.restart_child(sup, module.pool_registry()) do
          {:error, :running} -> {:ok, process2_id}
          e -> e
        end
      {:error, {{:already_started, process2_id}, _}} ->
        case Supervisor.restart_child(sup, module.pool_registry()) do
          {:error, :running} -> {:ok, process2_id}
          e -> e
        end
      error ->
        Logger.error(fn ->
          {
            """
            #{module}.start_registry_child #{inspect module.pool_registry()} Error
            #{inspect error}
            """, Noizu.ElixirCore.CallingContext.metadata(context)
          }
        end)
        :error
    end
  end

  defp start_task_supervisor(module, sup, context) do
    spec = task_supervisor_spec(module, context)
    case Supervisor.start_child(sup, spec) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, process2_id}} ->
        Supervisor.restart_child(module, process2_id)
      error ->
        Logger.error(fn ->
          {
            """
        
            #{module}.start_task_supervisor Error
            #{inspect error}
            """, Noizu.ElixirCore.CallingContext.metadata(context)}
        end)
        :error
    end
  end
  
  defp start_worker_supervisor_child(module, sup, definition, context) do
    #max_seconds = module.meta()[:max_seconds]
    #max_restarts = module.meta()[:max_restarts]

    case Supervisor.start_child(sup, module.pass_through_supervisor(module.pool_worker_supervisor(), [definition, context],  [shutdown: :infinity, restart: :permanent])) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, process2_id}} ->
        Supervisor.restart_child(module, process2_id)
      error ->
        Logger.error(fn ->
          {
            """

            #{module}.start_worker_supervisor_child #{inspect module.pool_worker_supervisor()} Error
            #{inspect error}
            """, Noizu.ElixirCore.CallingContext.metadata(context)}
        end)
        :error
    end
  end

  defp start_server_child(module, sup, definition, context) do
    #max_seconds = module.meta()[:max_seconds]
    #max_restarts = module.meta()[:max_restarts]

    case Supervisor.start_child(sup, module.pass_through_worker(module.pool_server(), [definition, context], [shutdown: :infinity, restart: :permanent])) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, process2_id}} ->
        Supervisor.restart_child(module, process2_id)
      error ->
        Logger.error(fn ->
          {
            """

            #{module}.start_server_child #{inspect module.pool_server()} Error
            #{inspect error}
            """, Noizu.ElixirCore.CallingContext.metadata(context)}
        end)
        :error
    end
  end

  defp start_monitor_child(module, sup, server_process, definition, context) do
    #max_seconds = module.meta()[:max_seconds]
    #max_restarts = module.meta()[:max_restarts]

    case Supervisor.start_child(sup, module.pass_through_worker(module.pool_monitor(), [server_process, definition, context], [shutdown: :infinity, restart: :permanent])) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, process2_id}} ->
        Supervisor.restart_child(module, process2_id)
      error ->
        Logger.error(fn ->
          {
            """

            #{module}.start_children(1) #{inspect module.pool_monitor()} Error.
            #{inspect error}
            """, Noizu.ElixirCore.CallingContext.metadata(context)}
        end)
        :error
    end
  end

end
