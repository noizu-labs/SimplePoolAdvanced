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
    message_processing_provider = Noizu.AdvancedPool.MessageProcessingBehaviour.DefaultProvider

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
      defdelegate start(definition \\ :default, context \\ nil), to: __MODULE__.PoolSupervisor, as: :start_link
      def start_remote(elixir_node, definition \\ :default, context \\ nil) do
        if (elixir_node == node()) do
          __MODULE__.PoolSupervisor.start_link(definition, context)
        else
          :rpc.call(elixir_node, __MODULE__.PoolSupervisor, :start_link, [definition, context])
        end
      end

      def stand_alone(), do: false


      #===========================================
      #-------------- Routing Delegates -------------------
      # Convenience methods should be placed at the pool level,
      # which will in turn hook into the Server.Router and worker spawning logic
      # to delivery commands to the correct worker processes.
      #----------------------------------------------------
      #===========================================
      defdelegate s_call(identifier, call, context, options \\ nil, timeout \\ nil), to: __MODULE__.Server.Router
      defdelegate s_call!(identifier, call, context, options \\ nil, timeout \\ nil), to: __MODULE__.Server.Router
      defdelegate s_cast(identifier, call, context, options \\ nil), to: __MODULE__.Server.Router
      defdelegate s_cast!(identifier, call, context, options \\ nil), to: __MODULE__.Server.Router
      defdelegate get_direct_link!(ref, context, options \\ nil), to: __MODULE__.Server.Router
      defdelegate link_forward!(link, call, context, options \\ nil), to: __MODULE__.Server.Router
      defdelegate server_call(call, context \\ nil, options \\ nil), to: __MODULE__.Server.Router, as: :self_call
      defdelegate server_cast(call, context \\ nil, options \\ nil), to: __MODULE__.Server.Router, as: :self_cast
      defdelegate server_internal_call(call, context \\ nil, options \\ nil), to: __MODULE__.Server.Router, as: :internal_call
      defdelegate server_internal_cast(call, context \\ nil, options \\ nil), to: __MODULE__.Server.Router, as: :internal_cast
      defdelegate remote_server_internal_call(remote_node, call, context \\ nil, options \\ nil), to: __MODULE__.Server.Router, as: :remote_call
      defdelegate remote_server_internal_cast(remote_node, call, context \\ nil, options \\ nil), to: __MODULE__.Server.Router, as: :remote_cast
      defdelegate server_system_call(call, context \\ nil, options \\ nil), to: __MODULE__.Server.Router, as: :internal_system_call
      defdelegate server_system_cast(call, context \\ nil, options \\ nil), to: __MODULE__.Server.Router, as: :internal_system_cast
      defdelegate remote_server_system_call(elixir_node, call, context \\ nil, options \\ nil), to: __MODULE__.Server.Router, as: :remote_system_call
      defdelegate remote_server_system_cast(elixir_node, call, context \\ nil, options \\ nil), to: __MODULE__.Server.Router, as: :remote_system_cast

      #==========================================================
      # Built in Worker Convenience Methods.
      #==========================================================
      defdelegate wake!(ref, request \\ :state, context \\ nil, options \\ nil), to: __MODULE__.Server
      defdelegate fetch!(ref, request \\ :state, context \\ nil, options \\ nil), to: __MODULE__.Server
      defdelegate save!(ref, args \\ {}, context \\ nil, options \\ nil), to: __MODULE__.Server
      defdelegate save_async!(ref, args \\ {}, context \\ nil, options \\ nil), to: __MODULE__.Server
      defdelegate reload!(ref, args \\ {}, context \\ nil, options \\ nil), to: __MODULE__.Server
      defdelegate reload_async!(ref, args \\ {}, context \\ nil, options \\ nil), to: __MODULE__.Server
      defdelegate load!(ref, args \\ {}, context \\ nil, options \\ nil), to: __MODULE__.Server
      defdelegate load_async!(ref, args \\ {}, context \\ nil, options \\ nil), to: __MODULE__.Server
      defdelegate ping(ref, args \\ {}, context \\ nil, options \\ nil), to: __MODULE__.Server
      defdelegate kill!(ref, args \\ {}, context \\ nil, options \\ nil), to: __MODULE__.Server
      defdelegate crash!(ref, args \\ {}, context \\ nil, options \\ nil), to: __MODULE__.Server
      defdelegate health_check!(ref, args \\ {}, context \\ nil, options \\ nil), to: __MODULE__.Server

      #--------------------------
      # Overridable
      #--------------------------
      defoverridable [
        start: 2,
        start_remote: 3,
        stand_alone: 0,

        #-----------------------------
        # Routing Overrides
        #-----------------------------
        s_call: 5,
        s_call!: 5,
        s_cast: 4,
        s_cast!: 4,
        get_direct_link!: 3,
        link_forward!: 4,
        server_call: 3,
        server_cast: 3,
        server_internal_call: 3,
        server_internal_cast: 3,
        remote_server_internal_call: 4,
        remote_server_internal_cast: 4,
        server_system_call: 3,
        server_system_cast: 3,
        remote_server_system_call: 4,
        remote_server_system_cast: 4,

      ]

      #--------------------------
      # Sub Modules
      #--------------------------
      if (unquote(default_modules[:worker])) do
        defmodule Worker do
          use Noizu.AdvancedPool.V3.WorkerBehaviour, unquote(options[:worker_options])
        end
      end

      if (unquote(default_modules[:server])) do
        defmodule Server do
          use Noizu.AdvancedPool.V3.ServerBehaviour, unquote(options[:server_options])
          def lazy_load(state), do: state
        end
      end

      if (unquote(default_modules[:worker_supervisor])) do
        defmodule WorkerSupervisor do
          use Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour, unquote(options[:worker_supervisor_options])
        end
      end

      if (unquote(default_modules[:pool_supervisor])) do
        defmodule PoolSupervisor do
          use Noizu.AdvancedPool.V3.PoolSupervisorBehaviour, unquote(options[:pool_supervisor_options])
        end
      end

      if (unquote(default_modules[:monitor])) do
        defmodule Monitor do
          use Noizu.AdvancedPool.V3.MonitorBehaviour, unquote(options[:monitor_options])
        end
      end

      if (unquote(default_modules[:record_keeper])) do
        defmodule RecordKeeper do
          use Noizu.AdvancedPool.RecordKeeperBehaviour, unquote(options[:record_keeper_options])
        end
      end

    end # end quote
  end #end __using__
end
