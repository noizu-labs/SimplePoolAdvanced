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

      #---------------------------------------
      #
      #---------------------------------------
      def short_name(), do: @short_name

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
      defdelegate wait_for_condition(condition, timeout \\ :infinity), to: Noizu.AdvancedPool.SettingsBehaviour.Default

      #---------------------------------------
      #
      #---------------------------------------
      # @deprecated
      defdelegate base(), to: @parent
      defdelegate pool(), to: @pool


      #---------------------------------------
      #
      #---------------------------------------
      defdelegate __worker_management__(), to: @pool

      #---------------------------------------
      #
      #---------------------------------------
      defdelegate __service_management__(), to: @pool


      #---------------------------------------
      #
      #---------------------------------------
      defdelegate pool_worker_supervisor(), to: @pool
      defdelegate __worker_supervisor__(), to: @pool

      #---------------------------------------
      #
      #---------------------------------------
      defdelegate pool_server(), to: @pool
      defdelegate __server__(), to: @pool

      #---------------------------------------
      #
      #---------------------------------------
      defdelegate __router__(), to: @pool

      #---------------------------------------
      #
      #---------------------------------------
      defdelegate pool_supervisor(), to: @pool
      defdelegate __supervisor__(), to: @pool

      #---------------------------------------
      #
      #---------------------------------------
      defdelegate pool_worker(), to: @pool
      defdelegate __worker__(), to: @pool

      #---------------------------------------
      #
      #---------------------------------------
      defdelegate pool_worker_state_entity(), to: @pool
      defdelegate __worker_state_entity__(), to: @pool

      #---------------------------------------
      #
      #---------------------------------------
      defdelegate pool_monitor(), to: @pool
      defdelegate __monitor__(), to: @pool

      #---------------------------------------
      #
      #---------------------------------------
      defdelegate pool_dispatch_table(), to: @pool
      defdelegate __dispatch_table__(), to: @pool

      #---------------------------------------
      #
      #---------------------------------------
      defdelegate pool_registry(), to: @pool
      defdelegate __registry__(), to: @pool

      #---------------------------------------
      #
      #---------------------------------------
      defdelegate node_manager(), to: @pool
      defdelegate __node_manager__(), to: @pool

      #---------------------------------------
      #
      #---------------------------------------
      defdelegate service_manager(), to: @pool
      defdelegate __service_manager__(), to: @pool

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
      def banner(msg), do: banner(@module, msg)
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
      """
      def meta_key(), do: __meta_key__()
      def __meta_key__(), do: @meta_key

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      Runtime meta/book keeping data for pool.
      """
      def meta(), do: __meta__()
      def __meta__(), do: Noizu.AdvancedPool.SettingsBehaviour.Default.meta(@module)

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      Append new entries to meta data (internally a map merge is performed).
      """
      def meta(update), do: __meta__(update)
      def __meta__(update), do: Noizu.AdvancedPool.SettingsBehaviour.Default.meta(@module, update)

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      Initial Meta Information for Module.
      """
      def meta_init(), do: __meta_init__()
      def __meta_init__(), do: Noizu.AdvancedPool.SettingsBehaviour.Default.meta_init(@module, %{stand_alone: @stand_alone})

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      retrieve effective compile time options/settings for pool.
      """
      def options(), do: __options__()
      def __options__(), do: @options

      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      retrieve extended compile time options information for this pool.
      """
      def option_settings(), do: __option_settings__()
      def __option_settings__(), do: @option_settings

      #---------------------------------------
      # overridable
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
