#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.WorkerSupervisor.Layer2Behaviour do
  @moduledoc """
    WorkerSupervisorBehaviour provides the logic for managing a pool of workers. The top level Pool Supervisors will generally
    contain a number of WorkerSupervisors that in turn are referenced by Pool.Server to access, kill and spawn worker processes.

    @todo increase level of OTP nesting and hide some of the communication complexity from Pool.Server
  """

  require Logger
  @callback start_link(any, any) :: any

  @callback child(any, any) :: any
  @callback child(any, any, any) :: any
  @callback child(any, any, any, any) :: any

  defmodule Default do
    @moduledoc """
      Provides the default implementation for WorkerSupervisor modules.
      Using the strategy pattern here allows us to move logic out of the WorkerSupervisorBehaviour implementation
      which reduces the amount of generated code, and improve compile times. It additionally allows for developers to provide
      their own alternative implementations.
    """
    alias Noizu.ElixirCore.OptionSettings
    alias Noizu.ElixirCore.OptionValue
    #alias Noizu.ElixirCore.OptionList

    require Logger

    @default_max_seconds (5)
    @default_max_restarts (1000)
    @default_strategy (:one_for_one)
    def prepare_options_slim(options), do: Noizu.ElixirCore.SlimOptions.slim(prepare_options(options))
    def prepare_options(options) do
      settings = %OptionSettings{
        option_settings: %{
          verbose: %OptionValue{option: :verbose, default: :auto},
          restart_type: %OptionValue{option: :restart_type, default: Application.get_env(:noizu_advanced_pool, :pool_restart_type, :transient)},
          max_restarts: %OptionValue{option: :max_restarts, default: Application.get_env(:noizu_advanced_pool, :pool_max_restarts, @default_max_restarts)},
          max_seconds: %OptionValue{option: :max_seconds, default: Application.get_env(:noizu_advanced_pool, :pool_max_seconds, @default_max_seconds)},
          strategy: %OptionValue{option: :strategy, default: Application.get_env(:noizu_advanced_pool, :pool_strategy, @default_strategy)}
        }
      }

      OptionSettings.expand(settings, options)
    end
  end

  defmacro __using__(option_settings) do
    #options = Macro.expand(options, __ENV__)
    implementation = Keyword.get(option_settings || [], :implementation, Noizu.AdvancedPool.V3.WorkerSupervisor.Layer2Behaviour.Default)
    #option_settings = implementation.prepare_options_slim(options)
    #_options = option_settings[:effective_options]
    #@TODO - use real options.
    message_processing_provider = Noizu.AdvancedPool.MessageProcessingBehaviour.DefaultProvider

    quote do
      @behaviour Noizu.AdvancedPool.V3.WorkerSupervisor.Layer2Behaviour
      use Supervisor
      require Logger
      alias Noizu.ElixirCore.CallingContext, as: Context
      @implementation unquote(implementation)

      #----------------------------------------
      @options :override
      @option_settings :override
      use Noizu.AdvancedPool.SettingsBehaviour.Inherited, unquote([option_settings: option_settings, depth: 2])
      use unquote(message_processing_provider), unquote(option_settings)
      #----------------------------------------

      def skinny_banner(contents), do: "   |> [#{base()}:WorkerSupervisor.#{@seg}] #{inspect self()} - #{contents}"


      #-----------
      #
      #-----------
      @doc """

      """
      def child(ref, context) do
        %{
          id: ref,
          start: {__worker__(), :start_link, [ref, context]},
          restart: @options.restart_type,
        }
      end

      @doc """

      """
      def child(ref, params, context) do
        %{
          id: ref,
          start: {__worker__(), :start_link, [ref, params, context]},
          restart: @options.restart_type,
        }
      end

      @doc """

      """
      def child(ref, params, context, options) do
        %{
          id: ref,
          start: {__worker__(), :start_link, [ref, params, context]},
          restart: (options.restart || @options.restart_type),
        }
      end

      #-----------
      #
      #-----------
      @doc """

      """
      def start_link(definition, context) do
        verbose() && Logger.debug(fn -> {skinny_banner("start_link: #{inspect definition, limit: 10}"), Context.metadata(context)} end)
        Supervisor.start_link(__MODULE__, [definition, context], [{:name, __MODULE__}])
      end

      #-----------
      #
      #-----------
      @doc """

      """
      def init([definition, context]) do
        verbose() && Logger.debug(fn -> {skinny_banner("init: #{inspect definition, limit: 10}"), Context.metadata(context)} end)
        Supervisor.init([], [{:strategy,  @options.strategy}, {:max_restarts, @options.max_restarts}, {:max_seconds, @options.max_seconds}])
      end

      defoverridable [
        start_link: 2,
        child: 2,
        child: 3,
        child: 4,
        init: 1,
      ]

    end # end quote
  end #end __using__

  defmacro __generate__(max_supervisors, options) do
    options = Macro.expand(options, __ENV__)
    implementation = Keyword.get(options || [], :implementation, Noizu.AdvancedPool.V3.WorkerSupervisor.Layer2Behaviour.Default)
    option_settings = implementation.prepare_options_slim(options)

    quote do
      module = __MODULE__
      leading = round(:math.floor(:math.log10(unquote(max_supervisors)))) + 1
      for i <- 1 .. unquote(max_supervisors) do
        defmodule :"#{module}.Seg#{String.pad_leading("#{i}", leading, "0")}" do
          @seg i
          use Noizu.AdvancedPool.V3.WorkerSupervisor.Layer2Behaviour, unquote(option_settings)
          #use unquote(layer2_provider), @l2o
        end
      end
    end
  end

end
