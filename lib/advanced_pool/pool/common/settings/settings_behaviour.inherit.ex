#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.SettingsBehaviour.Inherited do
  defmacro __using__(opts) do
    depth = opts[:depth] || 1
    option_settings = opts[:option_settings]
    options = option_settings[:effective_options]

    pool_worker_state_entity = Keyword.get(options, :worker_state_entity, :auto)
    stand_alone = opts[:stand_alone] || false

    quote do
      @depth unquote(depth)
      @behaviour Noizu.AdvancedPool.SettingsBehaviour
      @parent Module.split(__MODULE__) |> Enum.slice(0.. -2) |> Module.concat()
      @pool Module.split(__MODULE__) |> Enum.slice(0.. -(@depth + 1)) |> Module.concat()
      @module __MODULE__
      @module_str "#{@module}"
      @meta_key Module.concat(@module, Meta)
      @stand_alone unquote(stand_alone)
      @options Map.new(unquote(options) || [])
      @option_settings Map.new(unquote(option_settings) || [])

      # may not match pool_worker_state_entity
      @pool_worker_state_entity Noizu.AdvancedPool.SettingsBehaviour.Default.pool_worker_state_entity(@pool, unquote(pool_worker_state_entity))


      @short_name Module.split(__MODULE__) |> Enum.slice(-2..-1) |> Module.concat()

      def short_name(), do: @short_name

      def profile_start(%{meta: _} = state, profile \\ :default) do
        Noizu.AdvancedPool.SettingsBehaviour.Default.profile_start(state, profile)
      end

      def profile_end(%{meta: _} = state, profile \\ :default, opts \\ %{info: 100, warn: 300, error: 700, log: true}) do
        Noizu.AdvancedPool.SettingsBehaviour.Default.profile_end(state, profile, short_name(), opts)
      end

      defdelegate wait_for_condition(condition, timeout \\ :infinity), to: Noizu.AdvancedPool.SettingsBehaviour.Default

      # @deprecated
      defdelegate base(), to: @parent


      defdelegate pool(), to: @pool
      defdelegate pool_worker_supervisor(), to: @pool
      defdelegate pool_server(), to: @pool
      defdelegate pool_supervisor(), to: @pool
      defdelegate pool_worker(), to: @pool
      defdelegate pool_worker_state_entity(), to: @pool
      defdelegate pool_monitor(), to: @pool

      defdelegate pool_dispatch_table(), to: @pool
      defdelegate pool_registry(), to: @pool


      defdelegate node_manager(), to: @pool
      defdelegate service_manager(), to: @pool


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
