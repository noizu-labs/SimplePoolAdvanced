#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.MonitorBehaviour do
  @callback health_check(any, any) :: any
  @callback record_service_event!(any, any, any, any) :: any
  @callback lock!(any, any) :: any
  @callback release!(any, any) :: any

  defmacro __using__(options) do
    options = Macro.expand(options, __ENV__)
    implementation = Keyword.get(options || [], :implementation, Noizu.AdvancedPool.V3.ServerBehaviour.Default)
    option_settings = implementation.prepare_options_slim(options)

    # Temporary Hardcoding
    message_processing_provider = Noizu.AdvancedPool.MessageProcessingBehaviour.DefaultProvider

    quote do
      use GenServer
      @pool :pending
      use Noizu.AdvancedPool.SettingsBehaviour.Inherited, unquote([option_settings: option_settings])
      use unquote(message_processing_provider), unquote(option_settings)

      #---------------
      # start_link
      #---------------
      def start_link(server_process \\ :error, definition \\ :default, context \\ nil) do
        # @todo :wip
        GenServer.start_link(__MODULE__, [server_process, definition, context], [{:name, __MODULE__}, {:restart, :permanent}])
      end

      #---------------
      # init
      #---------------
      def init([server_process, definition, context] = args) do
        # @todo :wip
        {:ok, %{}}
      end

      def terminate(reason, state) do
        # @todo :wip
        :ok
      end

      def health_check(context, opts \\ %{}), do: :wip
      def record_service_event!(event, details, context, opts \\ %{}) do
        Noizu.AdvancedPool.V3.MonitorBehaviour.Default.record_service_event!(@pool, event, details, context, opts)
      end

      def lock!(context, opts \\ %{}), do: :wip
      def release!(context, opts \\ %{}), do: :wip


      #===============================================================================================================
      # Overridable
      #===============================================================================================================
      defoverridable [
        start_link: 3,
        init: 1,
        terminate: 2,
        health_check: 2,
        record_service_event!: 4,
        lock!: 2,
        release!: 2
      ]
    end
  end

end
