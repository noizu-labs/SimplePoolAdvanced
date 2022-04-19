#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.WorkerBehaviour.Default do
  alias Noizu.ElixirCore.OptionSettings
  alias Noizu.ElixirCore.OptionValue
  alias Noizu.ElixirCore.OptionList

  require Logger

  @features ([:auto_identifier, :lazy_load, :async_load, :inactivity_check, :s_redirect, :s_redirect_handle, :ref_lookup_cache, :call_forwarding, :graceful_stop, :crash_protection, :migrate_shutdown])
  @default_features ([:lazy_load, :s_redirect, :s_redirect_handle, :inactivity_check, :call_forwarding, :graceful_stop, :crash_protection, :migrate_shutdown])
  @default_check_interval_ms (1000 * 60 * 5)
  @default_kill_interval_ms (1000 * 60 * 15)
  def prepare_options_slim(options), do: Noizu.ElixirCore.SlimOptions.slim(prepare_options(options))
  def prepare_options(options) do
    settings = %OptionSettings{
      option_settings: %{
        features: %OptionList{option: :features, default: Application.get_env(:noizu_advanced_pool, :default_features, @default_features), valid_members: @features, membership_set: false},
        verbose: %OptionValue{option: :verbose, default: :auto},
        worker_state_entity: %OptionValue{option: :worker_state_entity, default: :auto},
        check_interval_ms: %OptionValue{option: :check_interval_ms, default: Application.get_env(:noizu_advanced_pool, :default_inactivity_check_interval_ms, @default_check_interval_ms)},
        kill_interval_ms: %OptionValue{option: :kill_interval_ms, default: Application.get_env(:noizu_advanced_pool, :default_inactivity_kill_interval_ms, @default_kill_interval_ms)},
      }
    }
    OptionSettings.expand(settings, options)
  end

  def skinny_banner(pool, contents), do: " |> [#{pool.base()}:Worker] #{inspect self()} - #{contents}"


  def init(pool_worker, {:migrate, ref, initial_state, context}) do

    wm = pool_worker.pool_server().worker_management()
    #server = pool_worker.pool_server()
    #base = pool_worker.pool()


    br = :os.system_time(:millisecond)
    wm.register!(ref, context)
    task = wm.set_node!(ref, context)
    r = Task.yield(task, 75)
    ar = :os.system_time(:millisecond)
    td = ar - br
    cond do
      td > 50 -> Logger.error(fn -> {pool_worker.banner("[Reg Time] - Critical #{__MODULE__} (#{inspect ref } = #{td} milliseconds"), Noizu.ElixirCore.CallingContext.metadata(context) } end)
      td > 25 -> Logger.warn(fn -> {pool_worker.banner("[Reg Time] - Delayed #{__MODULE__} (#{inspect ref } = #{td} milliseconds"), Noizu.ElixirCore.CallingContext.metadata(context) } end)
      td > 15 -> Logger.info(fn -> {pool_worker.banner("[Reg Time] - Slow #{__MODULE__} (#{inspect ref } = #{td} milliseconds"), Noizu.ElixirCore.CallingContext.metadata(context) } end)
      true -> :ok
    end
    # TODO V2 version needed.
    state = %Noizu.AdvancedPool.Worker.State{extended: %{set_node_task: r || task}, initialized: :delayed_init, worker_ref: ref, inner_state: {:transfer, initial_state}}
    {:ok, state}
  end

  def init(pool_worker, {ref, context}) do
    wm = pool_worker.__server__().__worker_management__()
    #server = pool_worker.pool_server()
    #base = pool_worker.pool()

    br = :os.system_time(:millisecond)
    register = wm.register!(ref, context)
    task = wm.set_node!(ref, context)
    r = Task.yield(task, 75)
    ar = :os.system_time(:millisecond)
    td = ar - br
    cond do
      td > 50 -> Logger.error(fn -> {pool_worker.banner("[Reg Time] - Critical #{__MODULE__} (#{inspect ref } = #{td} milliseconds"), Noizu.ElixirCore.CallingContext.metadata(context) } end)
      td > 25 -> Logger.warn(fn -> {pool_worker.banner("[Reg Time] - Delayed #{__MODULE__} (#{inspect ref } = #{td} milliseconds"), Noizu.ElixirCore.CallingContext.metadata(context) } end)
      td > 15 -> Logger.info(fn -> {pool_worker.banner("[Reg Time] - Slow #{__MODULE__} (#{inspect ref } = #{td} milliseconds"), Noizu.ElixirCore.CallingContext.metadata(context) } end)
      true -> :ok
    end
    # TODO V2 version needed.
    state = %Noizu.AdvancedPool.Worker.State{extended: %{set_node_task:  r || task}, initialized: :delayed_init, worker_ref: ref, inner_state: :start}
    {:ok, state}
  end

  def delayed_init(pool_worker, state, context) do

    # TODO load from meta
    inactivity_check = false
    lazy_load = true

    worker_state_entity = pool_worker.__worker_state_entity__()
    mod = pool_worker
    #wm = pool_worker.pool_server().worker_management()
    #server = pool_worker.pool_server()
    base = pool_worker.pool()

    ref = state.worker_ref
    ustate = case state.inner_state do
      # @TODO - investigate strategies for avoiding keeping full state in child def. Aka put into state that accepts a transfer/reads a transfer form a table, etc.
               {:transfer, {:state, initial_state, :time, time}} ->
                 cut_off = :os.system_time(:second) - 60*15
                 if time < cut_off do
                   if (mod.verbose()) do
                     Logger.info(fn -> {base.banner("INIT/1.stale_transfer#{__MODULE__} (#{inspect ref }"), Noizu.ElixirCore.CallingContext.metadata(context) } end)
                   end
                   #PRI-0 - disabled until rate limit available - spawn fn -> server.worker_lookup_handler().record_event!(ref, :start, :normal, context, %{}) end
                   {initialized, inner_state} = (if lazy_load do
                                                   case worker_state_entity.load(ref, context) do
                                                     nil -> {false, nil}
                                                     inner_state -> {true, inner_state}
                                                   end
                                                 else
                                                   {false, nil}
                                                 end)
                   %Noizu.AdvancedPool.Worker.State{initialized: initialized, worker_ref: ref, inner_state: inner_state}
                 else
                   mod.verbose() && Logger.debug(fn -> {skinny_banner(mod, "delayed_init.transfer #{inspect mod.__worker_state_entity__().sref(ref)}"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
                   #PRI-0 - disabled until rate limit available - spawn fn -> server.worker_lookup_handler().record_event!(ref, :start, :migrate, context, %{}) end
                   {initialized, inner_state} = worker_state_entity.transfer(ref, initial_state.inner_state, context)
                   %Noizu.AdvancedPool.Worker.State{initial_state| initialized: initialized, worker_ref: ref, inner_state: inner_state}
                 end

               {:transfer, initial_state} ->
                 mod.verbose() && Logger.debug(fn -> {skinny_banner(mod, "delayed_init.transfer #{inspect mod.__worker_state_entity__().sref(ref)}"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
                 #PRI-0 - disabled until rate limit available - spawn fn -> server.worker_lookup_handler().record_event!(ref, :start, :migrate, context, %{}) end
                 {initialized, inner_state} = worker_state_entity.transfer(ref, initial_state.inner_state, context)
                 %Noizu.AdvancedPool.Worker.State{initial_state| initialized: initialized, worker_ref: ref, inner_state: inner_state}
               :start ->
                 #PRI-0 - disabled until rate limit available - spawn fn -> server.worker_lookup_handler().record_event!(ref, :start, :normal, context, %{}) end
                 {initialized, inner_state} = (if lazy_load do
                                                 mod.verbose() && Logger.debug(fn -> {skinny_banner(mod, "delayed_init.start #{inspect mod.__worker_state_entity__().sref(ref)}"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
                                                 case worker_state_entity.load(ref, context) do
                                                   nil -> {false, nil}
                                                   inner_state -> {true, inner_state}
                                                 end
                                               else
                                                 mod.verbose() && Logger.debug(fn -> {skinny_banner(mod, "delayed_init.start (disabled!) #{inspect mod.__worker_state_entity__().sref(ref)}"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
                                                 {false, nil}
                                               end)
                 %Noizu.AdvancedPool.Worker.State{initialized: initialized, worker_ref: ref, inner_state: inner_state}
             end



    if inactivity_check do
      mod.schedule_inactivity_check(nil, %Noizu.AdvancedPool.Worker.State{ustate| last_activity: :os.system_time(:seconds)})
    else
      ustate
    end
  end

  def schedule_inactivity_check(check_interval_ms, context, state) do
    {:ok, t_ref} = :timer.send_after(check_interval_ms, self(), {:i, {:activity_check, state.worker_ref}, context})
    put_in(state, [Access.key(:extended), :t_ref], t_ref)
  end

  def clear_inactivity_check(state) do
    case Map.get(state.extended, :t_ref) do
      nil -> state
      t_ref ->
        :timer.cancel(t_ref)
        put_in(state, [Access.key(:extended), :t_ref], nil)
    end
  end

  def schedule_migrate_shutdown(migrate_shutdown_interval_ms, context, state) do
    {:ok, mt_ref} = :timer.send_after(migrate_shutdown_interval_ms, self(), {:i, {:migrate_shutdown, state.worker_ref}, context})
    put_in(state, [Access.key(:extended), :mt_ref], mt_ref)
  end

  def clear_migrate_shutdown(state) do
    case Map.get(state.extended, :mt_ref) do
      nil -> state
      mt_ref ->
        :timer.cancel(mt_ref)
        put_in(state, [Access.key(:extended), :mt_ref], nil)
    end
  end
end