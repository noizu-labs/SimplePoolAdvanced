#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.StandAloneServiceBehaviour do
  @moduledoc """
    The Noizu.AdvancedPool.V3.Behaviour provides the entry point for Worker Pools.
    The developer will define a pool such as ChatRoomPool that uses the Noizu.AdvancedPool.V3.Behaviour Implementation
    before going on to define worker and server implementations.

    The module is relatively straight forward, it provides methods to get pool information (pool worker, pool supervisor)
    compile options, runtime settings (via the FastGlobal library and our meta function).
  """

  defmacro __using__(options) do
    options = Macro.expand(options, __ENV__)
    implementation = Keyword.get(options || [], :implementation, Noizu.AdvancedPool.PoolBehaviour.Default)
    option_settings = implementation.prepare_options_slim(options)

    # Set stand alone flag.
    option_settings = option_settings
                      |> put_in([:effective_options, :stand_alone], true)
                      |> put_in([:effective_options, :monitor_options, :stand_alone], true)
                      |> put_in([:effective_options, :worker_options, :stand_alone], true)
                      |> put_in([:effective_options, :server_options, :stand_alone], true)
                      |> put_in([:effective_options, :worker_supervisor_options, :stand_alone], true)
                      |> put_in([:effective_options, :pool_supervisor_options, :stand_alone], true)

    options = option_settings[:effective_options]

    default_modules = options[:default_modules]
    message_processing_provider = Noizu.AdvancedPool.MessageProcessingBehaviour.DefaultProvider

    quote do
      require Logger
      @behaviour Noizu.AdvancedPool.PoolBehaviour
      @implementation unquote(implementation)
      @module __MODULE__

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      use Noizu.AdvancedPool.SettingsBehaviour.Base, unquote([option_settings: option_settings, stand_alone: true])

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      use unquote(message_processing_provider), unquote(option_settings)

      #--------------------------
      # Methods
      #--------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def start(definition \\ :default, context \\ nil), do: __supervisor__().start_link(definition, context)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def stand_alone(), do: true


      #-------------- Routing Delegates -------------------
      # Convenience methods should be placed at the pool level,
      # which will in turn hook into the Server.Router and worker spawning logic
      # to delivery commands to the correct worker processes.
      #----------------------------------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def s_call(identifier, call, context, options \\ nil, timeout \\ nil), do: __MODULE__.Server.Router.s_call(identifier, call, context, options, timeout)
      def s_call!(identifier, call, context, options \\ nil, timeout \\ nil), do: __MODULE__.Server.Router.s_call!(identifier, call, context, options, timeout)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def s_cast(identifier, call, context, options \\ nil), do: __MODULE__.Server.Router.s_cast(identifier, call, context, options)
      def s_cast!(identifier, call, context, options \\ nil), do: __MODULE__.Server.Router.s_cast!(identifier, call, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def get_direct_link!(ref, context, options \\ nil), do: __MODULE__.Server.Router.get_direct_link!(ref, context, options)
      def link_forward!(link, call, context, options \\ nil), do: __MODULE__.Server.Router.link_forward!(link, call, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def server_call(call, context \\ nil, options \\ nil), do: __MODULE__.Server.Router.self_call(call, context, options)
      def server_cast(call, context \\ nil, options \\ nil), do: __MODULE__.Server.Router.self_cast(call, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def server_internal_call(call, context \\ nil, options \\ nil), do: __MODULE__.Server.Router.internal_call(call, context, options)
      def server_internal_cast(call, context \\ nil, options \\ nil), do: __MODULE__.Server.Router.internal_cast(call, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def remote_server_internal_call(remote_node, call, context \\ nil, options \\ nil), do: __MODULE__.Server.Router.remote_call(remote_node, call, context, options)
      def remote_server_internal_cast(remote_node, call, context \\ nil, options \\ nil), do: __MODULE__.Server.Router.remote_cast(remote_node, call, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def server_system_call(call, context \\ nil, options \\ nil), do: __MODULE__.Server.Router.internal_system_call(call, context, options)
      def server_system_cast(call, context \\ nil, options \\ nil), do: __MODULE__.Server.Router.internal_system_cast(call, context, options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def remote_server_system_call(elixir_node, call, context \\ nil, options \\ nil), do: __MODULE__.Server.Router.remote_system_call(elixir_node, call, context, options)
      def remote_server_system_cast(elixir_node, call, context \\ nil, options \\ nil), do: __MODULE__.Server.Router.remote_system_cast(elixir_node, call, context, options)

      #--------------------------
      # Overridable
      #--------------------------
      defoverridable [
        start: 2,
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

      #-----------------------------------------
      # Sub Modules
      #-----------------------------------------

      # Note, no WorkerSupervisor as this is a stand alone service with no children.

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

      # Note user must implement Server sub module.

    end # end quote
  end #end __using__
end
