#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.ServiceManagementBehaviour do
  require Logger

  @callback default_definition() :: any
  @callback enable_server!(any) :: any
  @callback disable_server!(any) :: any
  @callback status(any) :: any
  @callback load_pool(any, any) :: any
  @callback load_complete(any, any, any) :: any
  @callback load_begin(any, any, any) :: any
  @callback status_wait(any, any, any) :: any
  @callback entity_status(any, any) :: any
  @callback server_kill!(any, any) :: any
  @callback service_health_check!(any) :: any
  @callback service_health_check!(any, any) :: any
  @callback service_health_check!(any, any, any) :: any
  @callback record_service_event!(any, any, any, any) :: any

  defmodule DefaultProvider do
    defmacro __using__(_options) do
      quote do
        require Logger
        @behaviour Noizu.AdvancedPool.V3.ServiceManagementBehaviour
        @pool_server Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat()
        alias Noizu.AdvancedPool.V3.Server.State, as: ServerState
        alias Noizu.AdvancedPool.Server.EnvironmentDetails
        alias Noizu.AdvancedPool.V3.ServiceManagement.ServiceManagementProvider, as: Provider

        @doc """
        Obtain service default definition.
        """
        def default_definition(), do: Provider.default_definition(@pool_server)

        @doc """
        Enable service.
        """
        def enable_server!(node), do: Provider.enable_server!(@pool_server, node)

        @doc """
        Disable service.
        """
        def disable_server!(node), do: Provider.disable_server!(@pool_server, node)

        @doc """
        Obtain service status.
        """
        def status(args \\ {}, context \\ nil), do: Provider.status(@pool_server, args, context)

        @doc """
        Load service pool.
        """
        def load_pool(args \\ {}, context \\ nil, options \\ nil), do: Provider.load_pool(@pool_server, args, context, options)

        @doc """
        Load pool complete callback.
        """
        def load_complete(this, process, context), do: Provider.load_complete(@pool_server, this, process, context)

        @doc """
        Begin async load_pool.
        """
        def load_begin(this, process, context), do: Provider.load_begin(@pool_server, this, process, context)

        @doc """
        Wait for service to meet target state.
        """
        def status_wait(target_state, context, timeout \\ :infinity), do: Provider.status_wait(@pool_server, target_state, context, timeout)

        @doc """
        Get entity status
        """
        def entity_status(context, options \\ %{}), do: Provider.entity_status(@pool_server, context, options)

        @doc """
        Kill service worker.
        """
        def server_kill!(args \\ {}, context \\ nil, options \\ %{}), do: Provider.server_kill!(@pool_server, args, context, options)

        @doc """
        Perform service health check.
        """
        def service_health_check!(%Noizu.ElixirCore.CallingContext{} = context), do: Provider.service_health_check!(@pool_server, context)
        def service_health_check!(health_check_options, %Noizu.ElixirCore.CallingContext{} = context), do: Provider.service_health_check!(@pool_server, health_check_options, context)
        def service_health_check!(health_check_options, %Noizu.ElixirCore.CallingContext{} = context, options), do: Provider.service_health_check!(@pool_server, health_check_options, context, options)

        @doc """
        Record service event.
        """
        def record_service_event!(event, details, context, options), do: Provider.record_service_event!(@pool_server, event, details, context, options)

        defoverridable [
          default_definition: 0,

          enable_server!: 1,
          disable_server!: 1,

          status: 1,

          load_pool: 2,
          load_complete: 3,
          load_begin: 3,

          status_wait: 3,

          entity_status: 2,

          server_kill!: 2,

          service_health_check!: 1,
          service_health_check!: 2,
          service_health_check!: 3,

          record_service_event!: 4,

        ]
      end
    end
  end


end
