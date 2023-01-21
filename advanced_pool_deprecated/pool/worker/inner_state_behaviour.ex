#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.InnerStateBehaviour do
  @moduledoc """
    The method provides scaffolding for Pool Worker Entities.  Such as support for calls such as shutdown, different init strategies, etc.

    @note this module is currently a duplicate of the V1 implementation
    @todo InnerStateBehaviour and WorkerBehaviour should be combined while moving the split between the Pool.Worker and the actual entity.
  """
  require Logger
  #@callback call_forwarding(call :: any, context :: any, from :: any,  state :: any, outer_state :: any) :: {atom, reply :: any, state :: any}
  @callback fetch!(state :: any, args :: any, from :: any, context :: any, options :: any) :: {:reply, this :: any, this :: any}
  @callback fetch!(state :: any, args :: any, from :: any, context :: any) :: {:reply, this :: any, this :: any}


  @callback load(ref :: any) ::  any
  @callback load(ref :: any, context :: any) :: any
  @callback load(ref :: any, context :: any, options :: any) :: any

  @callback terminate_hook(reason :: any,  Noizu.AdvancedPool.Worker.State.t) :: {:ok, Noizu.AdvancedPool.Worker.State.t}
  @callback shutdown(Noizu.AdvancedPool.Worker.State.t, context :: any, options :: any, from :: any) :: {:ok | :wait, Noizu.AdvancedPool.Worker.State.t}
  @callback worker_refs(any, any, any) :: any | nil

  @callback supervisor_hint(ref :: any) :: integer

  alias Noizu.ElixirCore.OptionSettings
  alias Noizu.ElixirCore.OptionValue
  alias Noizu.ElixirCore.OptionList

  @required_methods ([:call_forwarding, :load])
  @provided_methods ([:call_forwarding_catchall, :fetch, :shutdown, :terminate_hook, :get_direct_link!, :worker_refs, :ping!, :kill!, :crash!, :health_check!, :migrate_shutdown, :on_migrate, :transfer, :save!, :reload!, :supervisor_hint])

  @methods (@required_methods ++ @provided_methods)
  @features ([:auto_identifier, :lazy_load, :inactivitiy_check, :s_redirect])
  @default_features ([:lazy_load, :s_redirect, :inactivity_check])

  def prepare_options_slim(options), do: Noizu.ElixirCore.SlimOptions.slim(prepare_options(options))
  def prepare_options(options) do
    settings = %OptionSettings{
      option_settings: %{
        pool: %OptionValue{option: :pool, required: true},
        features: %OptionList{option: :features, default: Application.get_env(:noizu_advanced_pool, :default_features, @default_features), valid_members: @features, membership_set: false},
        only: %OptionList{option: :only, default: @provided_methods, valid_members: @methods, membership_set: true},
        override: %OptionList{option: :override, default: [], valid_members: @methods, membership_set: true},
      }
    }
    initial = OptionSettings.expand(settings, options)
    modifications = Map.put(initial.effective_options, :required, List.foldl(@methods, %{}, fn(x, acc) -> Map.put(acc, x, initial.effective_options.only[x] && !initial.effective_options.override[x]) end))
    %OptionSettings{initial| effective_options: Map.merge(initial.effective_options, modifications)}
  end

  def default_terminate_hook(server, reason, state) do
    case reason do
      {:shutdown, {:migrate, _ref, _, :to, _}} ->
        server.worker_management().unregister!(state.worker_ref, Noizu.ElixirCore.CallingContext.system(%{}))
        #PRI-0 - disabled until rate limit available - server.worker_management().record_event!(state.worker_ref, :migrate, reason, Noizu.ElixirCore.CallingContext.system(%{}), %{})
        reason
      {:shutdown, :migrate} ->
        server.worker_management().unregister!(state.worker_ref, Noizu.ElixirCore.CallingContext.system(%{}))
        #PRI-0 - disabled until rate limit available - server.worker_management().record_event!(state.worker_ref, :migrate, reason, Noizu.ElixirCore.CallingContext.system(%{}), %{})
        reason
      {:shutdown, _details} ->
        server.worker_management().unregister!(state.worker_ref, Noizu.ElixirCore.CallingContext.system(%{}))
        #PRI-0 - disabled until rate limit available - server.worker_management().record_event!(state.worker_ref, :shutdown, reason, Noizu.ElixirCore.CallingContext.system(%{}), %{})
        reason
      _ ->
        server.worker_management().unregister!(state.worker_ref, Noizu.ElixirCore.CallingContext.system(%{}))
        #PRI-0 - disabled until rate limit available - server.worker_management().record_event!(state.worker_ref, :terminate, reason, Noizu.ElixirCore.CallingContext.system(%{}), %{})
        reason
    end
    :ok
  end

  defmacro __using__(options) do
    option_settings = prepare_options_slim(options)
    options = option_settings[:effective_options]
    #required = options.required
    pool = options[:pool]
    message_processing_provider = Noizu.AdvancedPool.MessageProcessingBehaviour.DefaultProvider
    quote do
      import unquote(__MODULE__)
      @behaviour Noizu.AdvancedPool.V3.InnerStateBehaviour
      @base (unquote(Macro.expand(pool, __CALLER__)))
      @worker (Module.concat([@base, "Worker"]))
      @worker_supervisor (Module.concat([@base, "WorkerSupervisor"]))
      @server (Module.concat([@base, "Server"]))
      @pool_supervisor (Module.concat([@base, "PoolSupervisor"]))
      @simple_pool_group ({@base, @worker, @worker_supervisor, @server, @pool_supervisor})

      use unquote(message_processing_provider), unquote(option_settings)

      alias Noizu.AdvancedPool.Worker.Link

      #---------------------------------
      # supervisor_hint/1
      #---------------------------------
      @doc """
      Node residency hint.
      """
      def supervisor_hint(ref) do
        case id(ref) do
          v when is_integer(v) -> v
          {a, v} when is_atom(a) and is_integer(v) -> v # To allow for a common id pattern in a number of noizu related projects.
        end
      end

      #---------------------------------
      # get_direct_link!/2
      #---------------------------------
      @doc """
      Obtain a link structure that be used to call into a specific worker with cached pid caching to avoid unnecessary registry lookup.
      """
      def get_direct_link!(ref, context), do: @server.router().get_direct_link!(ref, context)


      #-------------------------------------------------------------------------------
      # Outer Context - Exceptions
      #-------------------------------------------------------------------------------
      def reload!(%Noizu.AdvancedPool.Worker.State{} = state, context, options) do
        case load(state.worker_ref, context, options) do
          nil -> {:reply, :error, state}
          inner_state ->
            {:reply, :ok, %Noizu.AdvancedPool.Worker.State{state| initialized: true, inner_state: inner_state, last_activity: :os.system_time(:seconds)}}
        end
      end

      #---------------------------------
      # save!/3
      #---------------------------------
      def save!(outer_state, context, _options) do
        Logger.warn("#{__MODULE__}.save method not implemented.", Noizu.ElixirCore.CallingContext.metadata(context))
        {:reply, {:error, :implementation_required}, outer_state}
      end

      #-------------------------------------------------------------------------------
      # Message Handlers
      #-------------------------------------------------------------------------------

      #-----------------------------
      # fetch!/4,5
      #-----------------------------
      def fetch!(state, args, from, context), do: fetch!(state, args, from, context, nil)
      def fetch!(state, _args, _from, _context, _options), do: {:reply, state, state}

      #---------------------------------
      #
      #---------------------------------
      def wake!(%__MODULE__{} = this, command, from, context), do: wake!(this, command, from, context, nil)
      def wake!(%__MODULE__{} = this, _command, _from, _context, _options), do: {:reply, this, this}

      #----------------------------------
      # routing
      #----------------------------------

      #------------------------------------------------------------------------
      # Infrastructure provided call router
      #------------------------------------------------------------------------

      #---------------------------------
      #
      #---------------------------------
      def __handle_call__({:passive, envelope}, from, state), do: __handle_call__(envelope, from, state)
      def __handle_call__({:spawn, envelope}, from, state), do: __handle_call__(envelope, from, state)

      # fetch
      def __handle_call__({:s, {:fetch!, args}, context}, from, state), do: fetch!(state, args, from, context)
      def __handle_call__({:s, {:fetch!, args, opts}, context}, from, state), do: fetch!(state, args, from, context, opts)

      def __handle_call__({:s, {:wake!, args}, context}, from, state), do: wake!(state, args, from, context)
      def __handle_call__({:s, {:wake!, args, opts}, context}, from, state), do: wake!(state, args, from, context, opts)

      def __handle_call__(call, from, state), do: super(call, from, state)

      #----------------------------
      #
      #----------------------------
      def __handle_cast__(call, state), do: __handle_call__(call, :cast, state) |> as_cast()

      #----------------------------
      #
      #----------------------------
      def __handle_info__(call, state), do: __handle_cast__(call, state) |> as_cast()

      #----------------------------------
      #
      #----------------------------------
      def shutdown(%Noizu.AdvancedPool.Worker.State{} = state, _context \\ nil, options \\ nil, _from \\ nil), do: {:ok, state}

      #---------------------------------
      #
      #---------------------------------
      def migrate_shutdown(%Noizu.AdvancedPool.Worker.State{} = state, _context \\ nil), do: {:ok, state}

      #---------------------------------
      #
      #---------------------------------
      def on_migrate(_rebase, %Noizu.AdvancedPool.Worker.State{} = state, _context \\ nil, _options \\ nil), do: {:ok, state}

      #---------------------------------
      #
      #---------------------------------
      def terminate_hook(reason, state), do: default_terminate_hook(@server, reason, state)

      #---------------------------------
      #
      #---------------------------------
      def worker_refs(_context, _options, _state), do: nil

      #---------------------------------
      #
      #---------------------------------
      def transfer(ref, transfer_state, _context \\ nil), do: {true, transfer_state}






      defoverridable [
        supervisor_hint: 1,
        get_direct_link!: 2,
        reload!: 3,
        save!: 3,
        fetch!: 4,
        fetch!: 5,
        wake!: 4,
        wake!: 5,

        __handle_call__: 3,
        __handle_cast__: 2,
        __handle_info__: 2,

        shutdown: 1,
        shutdown: 2,
        shutdown: 3,
        shutdown: 4,

        migrate_shutdown: 1,
        migrate_shutdown: 2,

        on_migrate: 2,
        on_migrate: 3,
        on_migrate: 4,

        terminate_hook: 2,
        worker_refs: 3,
        transfer: 2,
        transfer: 3,
      ]

    end # end quote
  end #end defmacro __using__(options)

end # end module
