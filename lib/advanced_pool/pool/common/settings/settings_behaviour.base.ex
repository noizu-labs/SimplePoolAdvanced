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

    #dispatch_table = options.dispatch_table
    #dispatch_monitor_table = options.dispatch_monitor_table
    #registry_options = options.registry_options

    service_manager = options[:service_manager]
    node_manager = options[:node_manager]



    quote do
      @behaviour Noizu.AdvancedPool.SettingsBehaviour
      @module __MODULE__
      @module_str "#{@module}"
      @meta_key Module.concat(@module, Meta)

      @stand_alone unquote(stand_alone)

      @pool @module
      @pool_server Module.concat([@pool, "Server"])
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


      defdelegate wait_for_condition(condition, timeout \\ :infinity), to: Noizu.AdvancedPool.SettingsBehaviour.Default

      def short_name(), do: @short_name

      def profile_start(%{meta: _} = state, profile \\ :default) do
        Noizu.AdvancedPool.SettingsBehaviour.Default.profile_start(state, profile)
      end

      def profile_end(%{meta: _} = state, profile \\ :default, opts \\ %{info: 100, warn: 300, error: 700, log: true}) do
        Noizu.AdvancedPool.SettingsBehaviour.Default.profile_end(state, profile, short_name(), opts)
      end

      # @deprecated
      def base, do: @pool
      def pool, do: @pool

      def pool_server, do: @pool_server
      def pool_supervisor, do: @pool_supervisor
      def pool_monitor, do: @pool_monitor
      def pool_worker_supervisor, do: @pool_worker_supervisor
      def pool_worker, do: @pool_worker
      def pool_worker_state_entity, do: @pool_worker_state_entity
      def pool_dispatch_table(), do: @pool_dispatch_table
      def pool_registry(), do: @pool_registry

      def node_manager(), do: @node_manager
      def service_manager(), do: @service_manager

      def banner(msg), do: banner(@module, msg)
      defdelegate banner(header, msg), to: Noizu.AdvancedPool.SettingsBehaviour.Default

      @doc """
      Get verbosity level.
      """
      def verbose(), do: meta()[:verbose]

      @doc """
        key used for persisting meta information. Defaults to __MODULE__.Meta
      """
      def meta_key(), do: @meta_key


      @doc """
      Runtime meta/book keeping data for pool.
      """
      def meta(), do: Noizu.AdvancedPool.SettingsBehaviour.Default.meta(@module)

      @doc """
      Append new entries to meta data (internally a map merge is performed).
      """
      def meta(update), do: Noizu.AdvancedPool.SettingsBehaviour.Default.meta(@module, update)

      @doc """
      Initial Meta Information for Module.
      """
      def meta_init(), do: Noizu.AdvancedPool.SettingsBehaviour.Default.meta_init(@module, %{stand_alone: @stand_alone})

      @doc """
      retrieve effective compile time options/settings for pool.
      """
      def options(), do: @options

      @doc """
      retrieve extended compile time options information for this pool.
      """
      def option_settings(), do: @option_settings


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
      ]
    end
  end
end
