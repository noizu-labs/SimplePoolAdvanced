#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.SettingsBehaviour.Base do
  defmacro __using__(opts) do
    option_settings = opts[:option_settings]
    options = option_settings[:effective_options]
    pool_worker_state_entity = Keyword.get(options, :worker_state_entity, :auto)
    stand_alone = opts[:stand_alone] || false
    service_manager = options[:service_manager]
    node_manager = options[:node_manager]

    quote do
      @behaviour Noizu.AdvancedPool.SettingsBehaviour
      @module __MODULE__
      @module_str "#{__MODULE__}"

      @meta_key Module.concat(__MODULE__, Meta)

      @stand_alone unquote(stand_alone)

      #-------
      # Pool Components
      #---------------------
      @pool __MODULE__
      @pool_server Module.concat([@pool, "Server"])
      @pool_router Module.concat([@pool, "Server.Router"])
      @pool_worker_management Module.concat([@pool, "Server.WorkerManagement"])
      @pool_service_management Module.concat([@pool, "Server.ServiceManagement"])
      @pool_supervisor Module.concat([@pool, "PoolSupervisor"])
      @pool_worker_supervisor Module.concat([@pool, "WorkerSupervisor"])
      @pool_worker Module.concat([@pool, "Worker"])
      @pool_monitor Module.concat([@pool, "Monitor"])
      @pool_registry Module.concat([@pool, "Registry"])

      @node_manager unquote(node_manager)
      @service_manager unquote(service_manager)

      @pool_dispatch_table Noizu.AdvancedPool.SettingsBehaviour.Default.expand_table(@pool, unquote(options)[:dispatch_table], DispatchTable)

      @options Map.new(unquote(options) || [])
      @option_settings Map.new(unquote(option_settings) || [])

      @pool_worker_state_entity Noizu.AdvancedPool.SettingsBehaviour.Default.pool_worker_state_entity(@pool, unquote(pool_worker_state_entity))

      @short_name Module.split(__MODULE__) |> Enum.slice(-1..-1) |> Module.concat()


      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      Wait for condition met.
      @todo rename __wait_for_condition__
      """
      defdelegate wait_for_condition(condition, timeout \\ :infinity), to: Noizu.AdvancedPool.SettingsBehaviour.Default

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @todo rename __short_name__
      """
      def short_name(), do: @short_name
      def __short_name__(), do: @short_name

      #---------------------------------------
      #
      #---------------------------------------
      def __profile_start__(%{meta: _} = state, profile \\ :default) do
        Noizu.AdvancedPool.SettingsBehaviour.Default.profile_start(state, profile)
      end

      #---------------------------------------
      #
      #---------------------------------------
      def __profile_end__(%{meta: _} = state, profile \\ :default, opts \\ %{info: 100, warn: 300, error: 700, log: true}) do
        Noizu.AdvancedPool.SettingsBehaviour.Default.profile_end(state, profile, short_name(), opts)
      end

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @todo remove
      @deprecated
      """
      def base, do: @pool

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @todo remove
      @deprecated
      """
      def pool, do: @pool

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @deprecated use __server__
      """
      def pool_server, do: __server__()
      def __server__, do: @pool_server

      #---------------------------------------
      #
      #---------------------------------------
      def __router__, do: @pool_router

      #---------------------------------------
      #
      #---------------------------------------
      def __worker_management__(), do: @pool_worker_management

      #---------------------------------------
      #
      #---------------------------------------
      def __service_management__(), do: @pool_service_management


      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @deprecated use __supervisor__
      """
      def pool_supervisor, do: __supervisor__()
      def __supervisor__, do: @pool_supervisor

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @deprecated use __monitor__
      """
      def pool_monitor, do: __monitor__()
      def __monitor__, do: @pool_monitor

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @deprecated use __worker_supervisor__
      """
      def pool_worker_supervisor, do: __worker_supervisor__()
      def __worker_supervisor__(), do: @pool_worker_supervisor

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @deprecated use __worker__
      """
      def pool_worker, do: __worker__()
      def __worker__, do: @pool_worker

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @deprecated use __worker_state_entity__
      """
      def pool_worker_state_entity, do: __worker_state_entity__()
      def __worker_state_entity__, do: @pool_worker_state_entity

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @deprecated use __dispatch_table__
      """
      def pool_dispatch_table(), do: __dispatch_table__()
      def __dispatch_table__(), do: @pool_dispatch_table

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @deprecated use __registry__
      """
      def pool_registry(), do: __registry__()
      def __registry__(), do: @pool_registry

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @deprecated use __node_manager__
      """
      def node_manager(), do: __node_manager__()
      def __node_manager__(), do: @node_manager

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      @deprecated use __service_manager__
      """
      def service_manager(), do: __service_manager__()
      def __service_manager__(), do: @service_manager

      #---------------------------------------
      #
      #---------------------------------------
      def __pool__() do
        [
        server: __server__(),
        router: __router__(),
        supervisor: __supervisor__(),
        monitor: __monitor__(),
        worker_supervisor: __worker_supervisor__(),
        worker: __worker__(),
        worker_state_entity: __worker_state_entity__(),
        dispatch_table: __dispatch_table__(),
        registry: __registry__(),
        node_manager: __node_manager__(),
        service_manager: __service_manager__(),
        worker_management: __worker_management__(),
        service_management: __service_management__(),
        ]
      end

      #---------------------------------------
      #
      #---------------------------------------
      def banner(msg), do: banner(__MODULE__, msg)
      def banner(header, msg), do: Noizu.AdvancedPool.SettingsBehaviour.Default.banner(header, msg)

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      Get verbosity level.
      """
      def verbose(), do: meta()[:verbose]

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
        key used for persisting meta information. Defaults to __MODULE__.Meta
        @deprecated use __meta_key__
      """
      def meta_key(), do: __meta_key__()
      def __meta_key__(), do: @meta_key
      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      Runtime meta/book keeping data for pool.
      @deprecated use __meta__
      """
      def meta(), do: __meta__()
      def __meta__(), do: Noizu.AdvancedPool.SettingsBehaviour.Default.meta(@module)

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      Append new entries to meta data (internally a map merge is performed).
      @deprecated use __meta__
      """
      def meta(update), do: __meta__(update)
      def __meta__(update), do: Noizu.AdvancedPool.SettingsBehaviour.Default.meta(@module, update)

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      Initial Meta Information for Module.
      @deprecated use __meta_init__
      """
      def meta_init(), do: __meta_init__()
      def __meta_init__(), do: Noizu.AdvancedPool.SettingsBehaviour.Default.meta_init(@module, %{stand_alone: @stand_alone})

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      retrieve effective compile time options/settings for pool.
      @deprecated use __options__
      """
      def options(), do: __options__()
      def __options__(), do: @options

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      retrieve extended compile time options information for this pool.
      @deprecated use __option_settings__
      """
      def option_settings(), do: __option_settings__()
      def __option_settings__(), do: @option_settings

      #---------------------------------------
      # Overridable
      #---------------------------------------
      defoverridable [
        wait_for_condition: 2,
        base: 0,
        pool: 0,
        pool_worker_supervisor: 0,
        pool_server: 0,
        pool_supervisor: 0,
        pool_worker: 0,
        pool_monitor: 0,
        pool_worker_state_entity: 0,
        banner: 1,
        banner: 2,
        verbose: 0,
        meta_key: 0,
        meta: 0,
        meta: 1,
        meta_init: 0,
        options: 0,
        option_settings: 0,



        __worker_management__: 0,
        __service_management__: 0,
        __worker_supervisor__: 0,
        __server__: 0,
        __router__: 0,
        __supervisor__: 0,
        __worker__: 0,
        __monitor__: 0,
        __worker_state_entity__: 0,
        __meta_key__: 0,
        __meta__: 0,
        __meta__: 1,
        __meta_init__: 0,
        __options__: 0,
        __option_settings__: 0,
        __pool__: 0,
      ]
    end
  end
end
