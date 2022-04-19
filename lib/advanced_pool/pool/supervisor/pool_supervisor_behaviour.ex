#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.PoolSupervisorBehaviour do

  @moduledoc """
  PoolSupervisorBehaviour provides the implementation for the top level node in a Pools OTP tree.
  The Pool Supervisor is responsible to monitoring the ServerPool and WorkerSupervisors (which in turn monitor workers)

  @todo Implement a top level WorkerSupervisor that in turn supervises children supervisors.
  """
  @callback start_link(any, any) :: any
  @callback start_children(any, any, any) :: any

  defmacro __using__(options) do
    options = Macro.expand(options, __ENV__)
    implementation = Keyword.get(options || [], :implementation, Noizu.AdvancedPool.V3.PoolSupervisorBehaviour.Default)
    option_settings = implementation.prepare_options_slim(options)
    #options = option_settings.effective_options
    #features = MapSet.new(options.features)
    message_processing_provider = Noizu.AdvancedPool.MessageProcessingBehaviour.DefaultProvider

    quote do
      @behaviour Noizu.AdvancedPool.V3.PoolSupervisorBehaviour
      use Supervisor
      require Logger

      @implementation unquote(implementation)
      @parent unquote(__MODULE__)
      @module __MODULE__

      #----------------------------
      use Noizu.AdvancedPool.SettingsBehaviour.Inherited, unquote([option_settings: option_settings])
      use unquote(message_processing_provider), unquote(option_settings)
      #--------------------------------

      @doc """
      Auto load setting for pool.
      """
      def auto_load(), do: __meta__()[:auto_load]

      @doc """
      start_link OTP entry point.
      """
      def start_link(definition \\ :auto, context \\ nil), do: @implementation.start_link(@module, definition, context)

      @doc """
      Start supervisor's children.
      """
      def start_children(sup, definition \\ :auto, context \\ nil), do: @implementation.start_children(@module, sup, definition, context)

      def add_child_supervisor(child, definition \\ :auto, context \\ nil), do: @implementation.add_child_supervisor(@module, child, definition, context)
      def add_child_worker(child, definition \\ :auto, context \\ nil), do: @implementation.add_child_worker(@module, child, definition, context)

      @doc """
      OTP Init entry point.
      """
      def init(arg), do: @implementation.init(@module, arg)

      #-------------------
      #
      #-------------------
      def pass_through_supervise(children,opts), do: Supervisor.init(children, opts)
      def pass_through_supervisor(definition, arguments, options) do
        %{
          id: options[:id] || definition,
          start: {definition, :start_link, arguments},
          restart: options[:restart] || :permanent,
          shutdown: options[:shutdown] || :infinity
        }
      end
  #, do: supervisor(definition, arguments, options)
      def pass_through_worker(definition, arguments, options) do
        %{
          id: options[:id] || definition,
          start: {definition, :start_link, arguments},
          restart: options[:restart] || :permanent,
          shutdown: options[:shutdown] || 5_000,
        }
      end

  #, do: worker(definition, arguments, options)

      defoverridable [
        start_link: 2,
        start_children: 3,
        init: 1,

        add_child_supervisor: 3,
        add_child_worker: 3,

        pass_through_supervise: 2,
        pass_through_supervisor: 3,
        pass_through_worker: 3,
      ]
    end # end quote
  end #end __using__
end
