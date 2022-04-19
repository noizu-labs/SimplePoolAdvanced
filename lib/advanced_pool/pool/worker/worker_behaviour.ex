#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.WorkerBehaviour do
  @moduledoc """
  Provides worker core functionality

  @note this module is still under heavy development, and is currently merely a copy of the V1 implementation with few structural changes.

  @todo combine InnerStateBehaviour and WorkerBehaviour, expose protocol or behavior method for accessing the Worker.State structure as needed.
  @todo rewrite call handler logic (simplify/cleanup) with a more straight forward path for extending handlers and consistent naming convention.
  """
  require Logger

  @callback delayed_init(any, any) :: any
  @callback schedule_migrate_shutdown(any, any) :: any
  @callback clear_migrate_shutdown(any) :: any
  @callback schedule_inactivity_check(any, any) :: any
  @callback clear_inactivity_check(any) :: any

  defmacro __using__(options) do
    options = Macro.expand(options, __ENV__)
    implementation = Keyword.get(options || [], :implementation, Noizu.AdvancedPool.V3.WorkerBehaviour.Default)
    option_settings = implementation.prepare_options_slim(options)
    options = option_settings[:effective_options]
    features = MapSet.new(options[:features])
    verbose = options[:verbose]


    message_processing_provider = Noizu.AdvancedPool.MessageProcessingBehaviour.DefaultProvider
    quote do
      import unquote(__MODULE__)
      require Logger
      #@behaviour Noizu.AdvancedPool.WorkerBehaviour
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      use GenServer

      @check_interval_ms (unquote(options[:check_interval_ms]))
      @kill_interval_s (unquote(options[:kill_interval_ms])/1000)
      @migrate_shutdown_interval_ms (5_000)
      @migrate_shutdown unquote(MapSet.member?(features, :migrate_shutdown))
      @inactivity_check unquote(MapSet.member?(features, :inactivity_check))
      @lazy_load unquote(MapSet.member?(features, :lazy_load))
      @base_verbose (unquote(verbose))
      #--------------------------------------------
      @option_settings :override
      @options :override
      @pool_worker_state_entity :override
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      alias Noizu.ElixirCore.CallingContext, as: Context
      use Noizu.AdvancedPool.SettingsBehaviour.Inherited, unquote([option_settings: option_settings])
      use unquote(message_processing_provider), unquote(option_settings)
      #--------------------------------------------

      def skinny_banner(contents), do: " |> [#{base()}:Worker] #{inspect self()} - #{contents}"



      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def start_link(ref, context) do
        verbose() && Logger.debug(fn -> {skinny_banner("start_link(#{Noizu.ERP.sref(ref)})"), Context.metadata(context)} end)

        case GenServer.start_link(__MODULE__, {ref, context}, [{:restart, :permanent}]) do
          {:ok, sup} ->
            verbose() && Logger.info(fn -> {skinny_banner("start_link Worker Initial Start. #{inspect sup}"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
            #module.start_children(sup, definition, context)
            {:ok, sup}
          {:error, {:already_started, sup}} ->
            verbose() && Logger.warn(fn -> {skinny_banner("start_link Worker Already Started. Handling Unexpected State. #{inspect sup}"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
            #module.start_children(sup, definition, context)
            {:ok, sup}
          {:error, {{:already_started, sup}, e}} ->
            verbose() && Logger.error(fn -> {skinny_banner("start_link Worker Already Started. Handling Unexpected State. #{inspect sup}:#{inspect e}"), Noizu.ElixirCore.CallingContext.metadata(context)} end)
            #module.start_children(sup, definition, context)
            {:ok, sup}
        end



      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def start_link(ref, migrate_args, context) do
        verbose() && Logger.debug(fn -> {skinny_banner("start_link(#{Noizu.ERP.sref(ref)}, :migrate)"), Context.metadata(context)} end)
        GenServer.start_link(__MODULE__, {:migrate, ref, migrate_args, context}, [{:restart, :permanent}])
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def terminate(reason, state) do
        verbose() && Logger.debug(fn -> skinny_banner("terminate(#{inspect reason}, #{Noizu.ERP.sref(state.worker_ref)})") end)
        @pool_worker_state_entity.terminate_hook(reason, Noizu.AdvancedPool.V3.WorkerBehaviour.Default.clear_inactivity_check(state))
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def init(arg) do
        verbose() && Logger.debug(fn -> skinny_banner("init(#{inspect arg, limit: 10})") end)
        Noizu.AdvancedPool.V3.WorkerBehaviour.Default.init(__MODULE__, arg)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def delayed_init(state, context) do
        verbose() && Logger.debug(fn -> {skinny_banner("delayed_init(#{Noizu.ERP.sref(state.worker_ref)})"), Context.metadata(context)} end)
        Noizu.AdvancedPool.V3.WorkerBehaviour.Default.delayed_init(__MODULE__, state, context)
      end
      #-------------------------------------------------------------------------
      # Inactivity Check Handling Feature Section
      #-------------------------------------------------------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def schedule_migrate_shutdown(context, state) do
        Noizu.AdvancedPool.V3.WorkerBehaviour.Default.schedule_migrate_shutdown(@migrate_shutdown_interval_ms, context, state)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def clear_migrate_shutdown(state) do
        Noizu.AdvancedPool.V3.WorkerBehaviour.Default.clear_migrate_shutdown(state)
      end

      #-------------------------------------------------------------------------
      # Inactivity Check Handling Feature Section
      #-------------------------------------------------------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def schedule_inactivity_check(context, state) do
        Noizu.AdvancedPool.V3.WorkerBehaviour.Default.schedule_inactivity_check(@check_interval_ms, context, state)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def clear_inactivity_check(state) do
        Noizu.AdvancedPool.V3.WorkerBehaviour.Default.clear_inactivity_check(state)
      end

      #------------------------------------------------------------------------
      # Infrastructure Provided Worker Calls
      #------------------------------------------------------------------------

      #-----------------------------
      # fetch!/4
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def fetch!(state, args, from, context), do: fetch!(state, args, from, context, nil)

      #-----------------------------
      # fetch!/5
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def fetch!(state, {:state}, _from, _context, _options), do: {:reply, state, state}
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def fetch!(state, {:default}, _from, _context, _options), do: {:reply, state, state}
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def fetch!(state, {:inner_state}, _from, _context, _options), do: {:reply, state.inner_state, state}
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def fetch!(state, {:process}, _from, _context, _options), do: {:reply, {is_map(state.inner_state) && Noizu.ERP.ref(state.inner_state) || state.inner_state, self(), node()}, state}
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def fetch!(_state, command, _from, _context, _options) do
        IO.puts "[[[UNHANDLED FETCH COMMAND: #{inspect command}]]]"
        nil  # all inner_state implementations
      end

      #-----------------------------
      # ping/5
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def ping(state, _args, _from, _context, _options \\ nil), do: {:reply, :pong, state}

      #-----------------------------
      # save!/5
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def save!(state, _args, _from, _context, _opts \\ nil) do
        Logger.error("#{__MODULE__}.save! Required")
        {:reply, :nyi, state}
      end

      #-----------------------------
      # reload!/5
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def reload!(state, _args, _from, context, _opts \\ nil) do
        verbose() && Logger.debug(fn -> {skinny_banner("reload(#{Noizu.ERP.sref(state.worker_ref)})"), Context.metadata(context)} end)
        {:reply, :nyi, state}
      end

      #-----------------------------
      # load!/5
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def load!(state, _args, _from, context, opts \\ nil) do
        verbose() && Logger.debug(fn -> {skinny_banner("load!(#{Noizu.ERP.sref(state.worker_ref)})"), Context.metadata(context)} end)

        worker_state_entity = __MODULE__.pool_worker_state_entity()
        inner_state = worker_state_entity.load(state.worker_ref, context, opts)
        state = %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, initialized: inner_state && true || false}
        {:reply, inner_state, state}
      end

      #-----------------------------
      # shutdown!/5
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def shutdown!(state, _args, _from, context, _opts \\ nil) do
        verbose() && Logger.debug(fn -> {skinny_banner("shutdown!(#{Noizu.ERP.sref(state.worker_ref)})"), Context.metadata(context)} end)
        {:reply, :nyi, state}
      end

      #-----------------------------
      # migrate!/5
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def migrate!(state, {ref, rebase} = _args, _from, context, _opts \\ nil) do
        Logger.error("#{__MODULE__}.migrate! NYI", Noizu.ElixirCore.CallingContext.metadata(context))
        {:reply, :nyi, state}
      end

      #-----------------------------
      # health_check!/5
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def health_check!(state, _args, _from, context, _opts \\ nil) do
        Logger.error("#{__MODULE__}.health_check! NYI", Noizu.ElixirCore.CallingContext.metadata(context))
        {:reply, :nyi, state}
      end

      #-----------------------------
      # kill!/5
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def kill!(state, _args, _from, context, _opts \\ nil) do
        {:stop, :shutdown, :user_shutdown, state}
      end

      #-----------------------------
      # crash!/5
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def crash!(state, _args, _from, _context, _opts \\ nil) do
        throw "#{__MODULE__} - Forced Crash!"
      end


      #-----------------------------
      # inactivity_check/5
      #-----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def inactivity_check(state, _args, _from, context, _opts \\ nil) do
        Logger.error("#{__MODULE__}.inactivity_check! NYI", Noizu.ElixirCore.CallingContext.metadata(context))
        {:noreply, state}
      end


      #------------------------------------------------------------------------
      # Infrastructure provided call router
      #------------------------------------------------------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"


      #def __handle_call__({type, _call, _context} = call, from, state) when type in [:s, :i, :m, :r], do: __handle_call__({:passive, call}, from, state)

      # fetch
      def __handle_call__({_,{:s, {:fetch!, args}, context}}, from, state), do: fetch!(state, args, from, context)
      def __handle_call__({_,{:s, {:fetch!, args, opts}, context}}, from, state), do: fetch!(state, args, from, context, opts)

      # ping!
      def __handle_call__({_,{:s, {:ping, args}, context}}, from, state), do: ping(state, args, from, context)
      def __handle_call__({_,{:s, {:ping, args, opts}, context}}, from, state), do: ping(state, args, from, context, opts)

      # health_check!
      def __handle_call__({_,{:s, {:health_check!, args}, context}}, from, state), do: health_check!(state, args, from, context)
      def __handle_call__({_,{:s, {:health_check!, args, opts}, context}}, from, state), do: health_check!(state, args, from, context, opts)

      # kill!
      def __handle_call__({_,{:s, {:kill!, args}, context}}, from, state), do: kill!(state, args, from, context)
      def __handle_call__({_,{:s, {:kill!, args, opts}, context}}, from, state), do: kill!(state, args, from, context, opts)

      # crash!
      def __handle_call__({_,{:s, {:crash!, args}, context}}, from, state), do: crash!(state, args, from, context)
      def __handle_call__({_,{:s, {:crash!, args, opts}, context}}, from, state), do: crash!(state, args, from, context, opts)

      # save!
      def __handle_call__({_,{:s, {:save!, args}, context}}, from, state), do: save!(state, args, from, context)
      def __handle_call__({_,{:s, {:save!, args, opts}, context}}, from, state), do: save!(state, args, from, context, opts)

      # reload!
      def __handle_call__({_,{:s, {:reload!, args}, context}}, from, state), do: reload!(state, args, from, context)
      def __handle_call__({_,{:s, {:reload!, args, opts}, context}}, from, state), do: reload!(state, args, from, context, opts)

      # load!
      def __handle_call__({_,{:s, {:load!, args}, context}}, from, state), do: load!(state, args, from, context)
      def __handle_call__({_,{:s, {:load!, args, opts}, context}}, from, state), do: load!(state, args, from, context, opts)

      # shutdown
      def __handle_call__({_,{:s, {:shutdown!, args}, context}}, from, state), do: shutdown!(state, args, from, context)
      def __handle_call__({_,{:s, {:shutdown!, args, opts}, context}}, from, state), do: shutdown!(state, args, from, context, opts)

      # migrate
      def __handle_call__({_,{:s, {:migrate!, args}, context}}, from, state), do: migrate!(state, args, from, context)
      def __handle_call__({_,{:s, {:migrate!, args, opts}, context}}, from, state), do: migrate!(state, args, from, context, opts)

      def __handle_call__({spawn? = :spawn, envelope}, from, state), do: __delegate_handle_call__({spawn?, envelope}, from, state)
      def __handle_call__({spawn? = :passive, envelope}, from, state), do: __delegate_handle_call__({spawn?, envelope}, from, state)



      #----------------------------
      #
      #----------------------------
      #def __handle_cast__({type, _call, _context} = call, state) when type in [:s, :i, :m, :r], do: __handle_cast__({:passive, call}, state)

      # health_check!
      def __handle_cast__({_,{:s, {:health_check!, args}, context}}, state), do: health_check!(state, args, :cast, context)
      def __handle_cast__({_,{:s, {:health_check!, args, opts}, context}}, state), do: health_check!(state, args, :cast, context, opts)

      # kill!
      def __handle_cast__({_,{:s, {:kill!, args}, context}}, state), do: kill!(state, args, :cast, context)
      def __handle_cast__({_,{:s, {:kill!, args, opts}, context}}, state), do: kill!(state, args, :cast, context, opts)

      # crash!
      def __handle_cast__({_,{:s, {:crash!, args}, context}}, state), do: crash!(state, args, :cast, context)
      def __handle_cast__({_,{:s, {:crash!, args, opts}, context}}, state), do: crash!(state, args, :cast, context, opts)

      # save!
      def __handle_cast__({_,{:s, {:save!, args}, context}}, state), do: save!(state, args, :cast, context)
      def __handle_cast__({_,{:s, {:save!, args, opts}, context}}, state), do: save!(state, args, :cast, context, opts)

      # reload!
      def __handle_cast__({_,{:s, {:reload!, args}, context}}, state), do: reload!(state, args, :cast, context)
      def __handle_cast__({_,{:s, {:reload!, args, opts}, context}}, state), do: reload!(state, args, :cast, context, opts)

      # load!
      def __handle_cast__({_,{:s, {:load!, args}, context}}, state), do: load!(state, args, :cast, context)
      def __handle_cast__({_,{:s, {:load!, args, opts}, context}}, state), do: load!(state, args, :cast, context, opts)

      # shutdown
      def __handle_cast__({_,{:s, {:shutdown!, args}, context}}, state), do: shutdown!(state, args, :cast, context)
      def __handle_cast__({_,{:s, {:shutdown!, args, opts}, context}}, state), do: shutdown!(state, args, :cast, context, opts)

      # migrate
      def __handle_cast__({_,{:s, {:migrate!, args}, context}}, state), do: migrate!(state, args, :cast, context)
      def __handle_cast__({_,{:s, {:migrate!, args, opts}, context}}, state), do: migrate!(state, args, :cast, context, opts)

      # Catch all
      def __handle_cast__({spawn? = :spawn, envelope}, state), do: __delegate_handle_cast__({spawn?, envelope}, state)
      def __handle_cast__({spawn? = :passive, envelope}, state), do: __delegate_handle_cast__({spawn?, envelope}, state)


      #----------------------------
      #
      #----------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      #def __handle_info__({:passive, envelope}, state), do: __handle_info__(envelope, state)
      #def __handle_info__({:spawn, envelope}, state), do: __handle_info__(envelope, state)

      def __handle_info__({_,{:i, {:inactivity_check, args}, context}}, state), do: inactivity_check(state, args, :info, context) |> as_cast()
      def __handle_info__({_,{:i, {:inactivity_check, args, opts}, context}}, state), do: inactivity_check(state, args, :info, context, opts) |> as_cast()

      def __handle_cast__({spawn? = :spawn, envelope}, state), do: __delegate_handle_cast__({spawn?, envelope}, state)
      def __handle_cast__({spawn? = :passive, envelope}, state), do: __delegate_handle_cast__({spawn?, envelope}, state)


      #===============================================================================================================
      # Overridable
      #===============================================================================================================
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      defoverridable [
        start_link: 2,
        start_link: 3,
        terminate: 2,
        init: 1,
        delayed_init: 2,
        schedule_migrate_shutdown: 2,
        clear_migrate_shutdown: 1,
        schedule_inactivity_check: 2,
        clear_inactivity_check: 1,

        # Infrastructure Provided Worker Methods
        fetch!: 4,
        fetch!: 5,
        ping: 5,
        save!: 5,
        reload!: 5,
        load!: 5,
        shutdown!: 5,
        migrate!: 5,
        health_check!: 5,
        kill!: 5,
        crash!: 5,
        inactivity_check: 5,

        # Routing for Infrastructure Provided Worker Methods
        __handle_call__: 3,
        __handle_cast__: 2,
        __handle_info__: 2,

      ]

    end # end quote
  end #end __using__
end
