#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.RouterBehaviour.PerformanceProvider do

  @moduledoc """
    PerformanceProvider: Router with redirect and exception handling disabled.
  """
  defmacro __using__(options) do
    options = options || %{}

    quote do
      alias Noizu.AdvancedPool.V3.Router.RouterProvider
      @options unquote(options)
      @pool_server Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat()

      @default_timeout 30_000
      @behaviour Noizu.AdvancedPool.RouterBehaviour

      def options(), do: @options
      def option(option, default \\ :option_not_found)
      def option(option, :option_not_found), do: Map.get(@options, option, {:option_not_found, option})
      def option(option, default), do: Map.get(@options, option, default)

      def __run_on_host__(ref, mfa, context, options \\ nil, timeout \\ @default_timeout) do
        RouterProvider.__run_on_host__(@pool_server, ref, mfa, context, options, timeout)
      end

      def __cast_to_host__(ref, mfa, context, options \\ nil) do
        RouterProvider.__cast_to_host__(@pool_server, ref, mfa, context, options)
      end

      def self_call(call, context \\ nil, options \\ nil) do
        RouterProvider.self_call(@pool_server, call, context, options)
      end

      def self_cast(call, context \\ nil, options \\ nil) do
        RouterProvider.self_cast(@pool_server, call, context, options)
      end


      def internal_system_call(call, context \\ nil, options \\ nil) do
        RouterProvider.internal_system_call(@pool_server, call, context, options)
      end

      def internal_system_cast(call, context \\ nil, options \\ nil) do
        RouterProvider.internal_system_cast(@pool_server, call, context, options)
      end


      def remote_system_call(remote_node, call, context \\ nil, options \\ nil) do
        RouterProvider.remote_system_call(@pool_server, remote_node, call, context, options)
      end

      def remote_system_cast(remote_node, call, context \\ nil, options \\ nil) do
        RouterProvider.remote_system_cast(@pool_server, remote_node, call, context, options)
      end


      def internal_call(call, context \\ nil, options \\ nil) do
        RouterProvider.internal_call(@pool_server, call, context, options)
      end

      def internal_cast(call, context \\ nil, options \\ nil) do
        RouterProvider.internal_cast(@pool_server, call, context, options)
      end


      def remote_call(remote_node, call, context \\ nil, options \\ nil) do
        RouterProvider.remote_call(@pool_server, remote_node, call, context, options)
      end

      def remote_cast(remote_node, call, context \\ nil, options \\ nil) do
        RouterProvider.remote_cast(@pool_server, remote_node, call, context, options)
      end



      def __s_call_unsafe__(ref, extended_call, context, options, timeout) do
        RouterProvider.__s_call_unsafe__(@pool_server, ref, extended_call, context, options, timeout)
      end

      def __s_cast_unsafe__(ref, extended_call, context, options) do
        RouterProvider.__s_cast_unsafe__(@pool_server, ref, extended_call, context, options)
      end


      def s_call!(identifier, call, context, options \\ nil, timeout \\ nil) do
        RouterProvider.s_call_no_crash_protection!(@pool_server, identifier, call, context, options, timeout)
      end

      def __rs_call__!(identifier, call, context, options \\ nil, timeout \\ nil) do
        RouterProvider.__rs_call_no_crash_protection__!(@pool_server, identifier, call, context, options, timeout)
      end

      def s_call(identifier, call, context, options \\ nil, timeout \\ nil) do
        RouterProvider.__s_call_no_crash_protection__(@pool_server, identifier, call, context, options, timeout)
      end

      def __rs_call__(identifier, call, context, options \\ nil, timeout \\ nil) do
        RouterProvider.__rs_call_no_crash_protection__(@pool_server, identifier, call, context, options, timeout)
      end

      def s_cast!(identifier, call, context, options \\ nil) do
        RouterProvider.__s_cast_no_crash_protection__!(@pool_server, identifier, call, context, options)
      end

      def __rs_cast__!(identifier, call, context, options \\ nil) do
        RouterProvider.__rs_cast_no_crash_protection__!(@pool_server, identifier, call, context, options)
      end

      def s_cast(identifier, call, context, options \\ nil) do
        RouterProvider.__s_cast_no_crash_protection__(@pool_server, identifier, call, context, options)
      end

      def __rs_cast__(identifier, call, context, options \\ nil) do
        RouterProvider.__rs_cast_no_crash_protection__(@pool_server, identifier, call, context, options)
      end

      def link_forward!(link, call, context, options \\ nil) do
        RouterProvider.link_forward!(@pool_server, link, call, context, options)
      end

      def __extended_call__(s_type, ref, call, context, options, timeout) do
        RouterProvider.__extended_call_without_redirect_support__(@pool_server, s_type, ref, call, context, options, timeout)
      end

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
        options: 2,

        __extended_call__: 6,

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
        __s_call_unsafe__: 5,
        __s_cast_unsafe__: 4,

        s_call!: 5,
        __rs_call__!: 5,

        s_call: 5,
        __rs_call__: 5,

        s_cast!: 4,
        __rs_cast__!: 4,

        s_cast: 4,
        __rs_cast__: 4,

        link_forward!: 4,

        __run_on_host__: 5,
        __cast_to_host__: 4,
      ]
    end
  end
end
