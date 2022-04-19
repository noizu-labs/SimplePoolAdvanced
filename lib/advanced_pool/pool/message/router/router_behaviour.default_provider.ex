#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.RouterBehaviour.DefaultProvider do
  @moduledoc """
    DefaultRouter: Provides set of configurations most users are anticipated to desire.
     - Supports Redirects
     - Supports Safe Calls
  """


  defmacro __using__(options) do
    #options = options || %{}
    # @TODO use provided options
    options = options[:effective_options]
    quote do
      alias Noizu.AdvancedPool.V3.Router.RouterProvider
      @options Map.new(unquote(Macro.escape(options)) || [])
      @pool_server Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat()
      @default_timeout 30_000
      @behaviour Noizu.AdvancedPool.RouterBehaviour

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def options(), do: @options
      def option(option, default \\ :option_not_found)
      def option(option, :option_not_found), do: Map.get(@options, option, {:option_not_found, option})
      def option(option, default), do: Map.get(@options, option, default)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def skinny_banner(contents), do: " |> [#{@pool_server.base()}:Worker] #{inspect self()} - #{contents}"

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def run_on_host(ref, mfa, context, options \\ nil, timeout \\ @default_timeout) do
        RouterProvider.run_on_host(@pool_server, ref, mfa, context, options, timeout)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def cast_to_host(ref, mfa, context, options \\ nil) do
        RouterProvider.cast_to_host(@pool_server, ref, mfa, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def self_call(call, context \\ nil, options \\ nil) do
        RouterProvider.self_call(@pool_server, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def self_cast(call, context \\ nil, options \\ nil) do
        RouterProvider.self_cast(@pool_server, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def internal_system_call(call, context \\ nil, options \\ nil) do
        RouterProvider.internal_system_call(@pool_server, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def internal_system_cast(call, context \\ nil, options \\ nil) do
        RouterProvider.internal_system_cast(@pool_server, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def remote_system_call(remote_node, call, context \\ nil, options \\ nil) do
        RouterProvider.remote_system_call(@pool_server, remote_node, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def remote_system_cast(remote_node, call, context \\ nil, options \\ nil) do
        RouterProvider.remote_system_cast(@pool_server, remote_node, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def internal_call(call, context \\ nil, options \\ nil) do
        RouterProvider.internal_call(@pool_server, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def internal_cast(call, context \\ nil, options \\ nil) do
        RouterProvider.internal_cast(@pool_server, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def remote_call(remote_node, call, context \\ nil, options \\ nil) do
        RouterProvider.remote_call(@pool_server, remote_node, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def remote_cast(remote_node, call, context \\ nil, options \\ nil) do
        RouterProvider.remote_cast(@pool_server, remote_node, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def s_call_unsafe(ref, extended_call, context, options, timeout) do
        RouterProvider.s_call_unsafe(@pool_server, ref, extended_call, context, options, timeout)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def s_cast_unsafe(ref, extended_call, context, options) do
        RouterProvider.s_cast_unsafe(@pool_server, ref, extended_call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def s_call!(identifier, call, context, options \\ nil, timeout \\ nil) do
        RouterProvider.s_call_crash_protection!(@pool_server, identifier, call, context, options, timeout)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def rs_call!(identifier, call, context, options \\ nil, timeout \\ nil) do
        RouterProvider.rs_call_crash_protection!(@pool_server, identifier, call, context, options, timeout)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def s_call(identifier, call, context, options \\ nil, timeout \\ nil) do
        RouterProvider.s_call_crash_protection(@pool_server, identifier, call, context, options, timeout)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def rs_call(identifier, call, context, options \\ nil, timeout \\ nil) do
        RouterProvider.rs_call_crash_protection(@pool_server, identifier, call, context, options, timeout)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def s_cast!(identifier, call, context, options \\ nil) do
        RouterProvider.s_cast_crash_protection!(@pool_server, identifier, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def rs_cast!(identifier, call, context, options \\ nil) do
        RouterProvider.rs_cast_crash_protection!(@pool_server, identifier, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def s_cast(identifier, call, context, options \\ nil) do
        RouterProvider.s_cast_crash_protection(@pool_server, identifier, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def rs_cast(identifier, call, context, options \\ nil) do
        RouterProvider.rs_cast_crash_protection(@pool_server, identifier, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def link_forward!(link, call, context, options \\ nil) do
        RouterProvider.link_forward!(@pool_server, link, call, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def extended_call(s_type, ref, call, context, options, timeout) do
        RouterProvider.extended_call_with_redirect_support(@pool_server, s_type, ref, call, context, options, timeout)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def get_direct_link!(ref, context, options) do
        RouterProvider.get_direct_link!(@pool_server, ref, context, options)
      end


      #def route_call(envelope, from, state) do
      #  RouterProvider.route_call(@pool_server, envelope, from, state)
      #end

      #def route_cast(envelope, state) do
      #  RouterProvider.route_cast(@pool_server, envelope, state)
      #end

      #def route_info(envelope, state) do
      #  RouterProvider.route_info(@pool_server, envelope, state)
      #end





      defoverridable [
        options: 0,
        option: 2,

        extended_call: 6,

        self_call: 3,
        self_cast: 3,

        internal_system_call: 3,
        internal_system_cast: 3,

        internal_call: 3,
        internal_cast: 3,

        remote_system_call: 4,
        remote_system_cast: 4,

        remote_call: 4,
        remote_cast: 4,

        get_direct_link!: 3,
        s_call_unsafe: 5,
        s_cast_unsafe: 4,

        #route_call: 3,
        #route_cast: 2,
        #route_info: 2,

        s_call!: 5,
        rs_call!: 5,

        s_call: 5,
        rs_call: 5,

        s_cast!: 4,
        rs_cast!: 4,

        s_cast: 4,
        rs_cast: 4,

        link_forward!: 4,

        run_on_host: 5,
        cast_to_host: 4,
      ]
    end
  end
end
