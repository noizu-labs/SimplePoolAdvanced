#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.PoolBehaviour do
  @callback stand_alone() :: any

  defmacro __using__(options) do
    options = Macro.expand(options, __ENV__)
    implementation = Keyword.get(options || [], :implementation, Noizu.AdvancedPool.PoolBehaviour.Default)
    option_settings = implementation.prepare_options_slim(options)
    options = option_settings[:effective_options]
    default_modules = options[:default_modules]
    max_supervisors = options[:max_supervisors]
    message_processing_provider = options[:message_provider] || Noizu.AdvancedPool.MessageProcessingBehaviour.DefaultProvider

    include_worker_module = default_modules[:worker]
    include_server_module = default_modules[:server]
    include_worker_supervisor_module = default_modules[:worker_supervisor]
    include_pool_supervisor_module = default_modules[:pool_supervisor]
    include_monitor_module = default_modules[:monitor]
    include_record_keeper_module = default_modules[:record_keeper]

    worker_module_options = options[:worker_options]
    server_module_options = options[:server_options]
    worker_supervisor_module_options = options[:worker_supervisor_options]
    pool_supervisor_module_options = options[:pool_supervisor_options]
    monitor_module_options = options[:monitor_options]
    record_keeper_module_options = options[:record_keeper_options]


    quote do
      require Logger
      @behaviour Noizu.AdvancedPool.PoolBehaviour
      @implementation unquote(implementation)
      @module __MODULE__
      @max_supervisors unquote(max_supervisors)

      #================================================================================================================
      # Load Settings and Message Processing
      #================================================================================================================
      use Noizu.AdvancedPool.SettingsBehaviour.Base, unquote([option_settings: option_settings])
      use unquote(message_processing_provider), unquote(option_settings)

      #===========================================
      # Methods
      #===========================================


      #---------------------------------------
      #
      #---------------------------------------
      @doc """
      GenServer.start pool.
      """
      def start(definition \\ :default, context \\ nil), do: __supervisor__().start_link(definition, context)

      #---------------------------------------
      #
      #---------------------------------------
      def start_remote(elixir_node, definition \\ :default, context \\ nil) do
        if (elixir_node == node()) do
          __supervisor__().start_link(definition, context)
        else
          :rpc.call(elixir_node, __supervisor__(), :start_link, [definition, context])
        end
      end

      #---------------------------------------
      #
      #---------------------------------------
      def stand_alone(), do: false


      #===========================================
      #-------------- Routing Delegates -------------------
      # Convenience methods should be placed at the pool level,
      # which will in turn hook into the Server.Router and worker spawning logic
      # to delivery commands to the correct worker processes.
      #----------------------------------------------------
      #===========================================
      def s_call(identifier, call, context, options \\ nil, timeout \\ nil), do: __router__().s_call(identifier, call, context, options, timeout)
      def s_call!(identifier, call, context, options \\ nil, timeout \\ nil), do: __router__().s_call!(identifier, call, context, options, timeout)
      def s_cast(identifier, call, context, options \\ nil), do: __router__().s_cast(identifier, call, context, options)
      def s_cast!(identifier, call, context, options \\ nil), do: __router__().s_cast!(identifier, call, context, options)
      def get_direct_link!(ref, context, options \\ nil), do: __router__().get_direct_link!(ref, context, options)
      def link_forward!(link, call, context, options \\ nil), do: __router__().link_forward!(link, call, context, options)
      def server_call(call, context \\ nil, options \\ nil), do: __router__().self_call(call, context, options)
      def server_cast(call, context \\ nil, options \\ nil), do: __router__().self_cast(call, context, options)
      def server_internal_call(call, context \\ nil, options \\ nil), do: __router__().internal_call(call, context, options)
      def server_internal_cast(call, context \\ nil, options \\ nil), do: __router__().internal_cast(call, context, options)
      def remote_server_internal_call(remote_node, call, context \\ nil, options \\ nil), do: __router__().remote_call(remote_node, call, context, options)
      def remote_server_internal_cast(remote_node, call, context \\ nil, options \\ nil), do: __router__().remote_cast(remote_node, call, context, options)
      def server_system_call(call, context \\ nil, options \\ nil), do: __router__().internal_system_call(call, context, options)
      def server_system_cast(call, context \\ nil, options \\ nil), do: __router__().internal_system_cast(call, context, options)
      def remote_server_system_call(elixir_node, call, context \\ nil, options \\ nil), do: __router__().remote_system_call(elixir_node, call, context, options)
      def remote_server_system_cast(elixir_node, call, context \\ nil, options \\ nil), do: __router__().remote_system_cast(elixir_node, call, context, options)

      #==========================================================
      # Built in Worker Convenience Methods.
      #==========================================================
      def wake!(ref, request \\ :state, context \\ nil, options \\ nil), do: __server__().wake!(ref, request, context, options)
      def fetch!(ref, request \\ :state, context \\ nil, options \\ nil), do: __server__().fetch!(ref, request, context, options)
      def save!(ref, args \\ {}, context \\ nil, options \\ nil), do: __server__().save!(ref, args, context, options)
      def save_async!(ref, args \\ {}, context \\ nil, options \\ nil), do: __server__().save_async!(ref, args, context, options)
      def reload!(ref, args \\ {}, context \\ nil, options \\ nil), do: __server__().reload!(ref, args, context, options)
      def reload_async!(ref, args \\ {}, context \\ nil, options \\ nil), do: __server__().reload_async!(ref, args, context, options)
      def load!(ref, args \\ {}, context \\ nil, options \\ nil), do: __server__().load!(ref, args, context, options)
      def load_async!(ref, args \\ {}, context \\ nil, options \\ nil), do: __server__().load_async!(ref, args, context, options)
      def ping(ref, args \\ {}, context \\ nil, options \\ nil), do: __server__().ping(ref, args, context, options)
      def kill!(ref, args \\ {}, context \\ nil, options \\ nil), do: __server__().kill!(ref, args, context, options)
      def crash!(ref, args \\ {}, context \\ nil, options \\ nil), do: __server__().crash!(ref, args, context, options)
      def health_check!(ref, args \\ {}, context \\ nil, options \\ nil), do: __server__().health_check!(ref, args, context, options)

      #--------------------------
      # Overridable
      #--------------------------
      defoverridable [
        start: 2,
        start_remote: 3,
        stand_alone: 0,
      ]

      #--------------------------
      # Sub Modules
      #--------------------------
      if (unquote(include_worker_module)) do
        defmodule Worker do
          use Noizu.AdvancedPool.V3.WorkerBehaviour, unquote(worker_module_options)
        end
      end

      if (unquote(include_server_module)) do
        defmodule Server do
          use Noizu.AdvancedPool.V3.ServerBehaviour, unquote(server_module_options)
          def lazy_load(state), do: state
        end
      end

      if (unquote(include_worker_supervisor_module)) do
        defmodule WorkerSupervisor do
          use Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour, unquote(worker_supervisor_module_options)
        end
      end

      if (unquote(include_pool_supervisor_module)) do
        defmodule PoolSupervisor do
          use Noizu.AdvancedPool.V3.PoolSupervisorBehaviour, unquote(pool_supervisor_module_options)
        end
      end

      if (unquote(include_monitor_module)) do
        defmodule Monitor do
          use Noizu.AdvancedPool.V3.MonitorBehaviour, unquote(monitor_module_options)
        end
      end

      if (unquote(include_record_keeper_module)) do
        defmodule RecordKeeper do
          use Noizu.AdvancedPool.RecordKeeperBehaviour, unquote(record_keeper_module_options)
        end
      end

    end # end quote
  end #end __using__
end
