#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour do
  @moduledoc """
    WorkerSupervisorBehaviour provides the logic for managing a pool of workers. The top level Pool Supervisors will generally
    contain a number of WorkerSupervisors that in turn are referenced by Pool.Server to access, kill and spawn worker processes.

    @todo increase level of OTP nesting and hide some of the communication complexity from Pool.Server
  """
  require Logger

  @callback worker_start(any, any) :: any
  @callback worker_start(any, any, any) :: any

  @callback supervisor_by_index(any) :: any
  @callback available_supervisors() :: any
  @callback active_supervisors() :: any

  @callback count_children() :: any
  @callback group_children(any) :: any
  @callback current_supervisor(any) :: any

  defmacro __using__(options) do
    options = Macro.expand(options, __ENV__)
    implementation = Keyword.get(options || [], :implementation, Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour.Default)
    option_settings = implementation.prepare_options_slim(options)
    options = option_settings[:effective_options]

    # @Todo Temporary Hard Code
    max_supervisors = options[:max_supervisors]
    layer2_provider = options[:layer2_provider]

    message_processing_provider = Noizu.AdvancedPool.MessageProcessingBehaviour.DefaultProvider
    quote do
      @behaviour Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour
      use Supervisor
      require Logger
      alias Noizu.ElixirCore.CallingContext, as: Context
      @implementation unquote(implementation)
      @options :override
      @option_settings :override
      @max_supervisors unquote(max_supervisors)

      use Noizu.AdvancedPool.SettingsBehaviour.Inherited, unquote([option_settings: option_settings])
      use unquote(message_processing_provider), unquote(option_settings)


      def skinny_banner(contents), do: " |> [#{base()}:WorkerSupervisor] #{inspect self()} - #{contents}"

      def worker_start(ref, transfer_state, context), do: Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour.Default.worker_start(__MODULE__, ref, transfer_state, context)
      def worker_start(ref, context), do: Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour.Default.worker_start(__MODULE__, ref, context)

      @doc """
      OTP start_link entry point.
      """
      def start_link(definition, context) do
        verbose() && Logger.debug(fn -> {skinny_banner("start_link"), Context.metadata(context)} end)
        Supervisor.start_link(__MODULE__, [definition, context], [{:name, __MODULE__}])
      end

      @doc """
      OTP init entry point.
      """
      def init([definition, context] = args) do
        verbose() && Logger.debug(fn -> {skinny_banner("init(#{inspect args, limit: 10})"), Context.metadata(context)} end)
        available_supervisors()
        |> Enum.map(
             fn(worker_supervisor_name) ->
               %{
                 id: worker_supervisor_name,
                 start: {worker_supervisor_name, :start_link, [definition, context]},
                 restart: @options.layer2_restart_type,
               }
             end)
        |> Supervisor.init([
          strategy: @options.strategy,
          max_restarts: @options.layer2_max_restarts,
          max_seconds: @options.layer2_max_seconds
        ])
      end


      @doc """
      Initial Meta Information for Module.
      """
      def meta_init(), do: Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour.Default.meta_init(__MODULE__)
      def __meta_init__(), do: Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour.Default.meta_init(__MODULE__)

      def supervisor_by_index(index), do: __meta__()[:supervisor_by_index][index]
      def available_supervisors(), do: __meta__()[:available_supervisors]
      def active_supervisors(), do: __meta__()[:active_supervisors]

      def group_children(group_fn), do: Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour.Default.group_children(__MODULE__, group_fn)
      def count_children(), do: Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour.Default.count_children(__MODULE__)
      def current_supervisor(ref), do: Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour.Default.current_supervisor(__MODULE__, ref)


      defoverridable [
        start_link: 2,
        init: 1,

        worker_start: 3,
        worker_start: 2,

        supervisor_by_index: 1,
        available_supervisors: 0,
        active_supervisors: 0,

        group_children: 1,
        count_children: 0,
        current_supervisor: 1,
      ]

      #==================================================
      # Generate Sub Supervisors
      #==================================================
      require unquote(layer2_provider)
      unquote(layer2_provider).__generate__(@max_supervisors, unquote(options[:layer2_options] || []))



    end # end quote
  end #end __using__
end
