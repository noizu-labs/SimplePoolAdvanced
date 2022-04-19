#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.WorkerSupervisorBehaviour.Default do
  @moduledoc """
  Reusable functionality implemented here to reduce size of generated code.
  """
  alias Noizu.ElixirCore.OptionSettings
  alias Noizu.ElixirCore.OptionValue
  #alias Noizu.ElixirCore.OptionList
  @default_max_seconds (5)
  @default_max_restarts (1000)
  @default_strategy (:one_for_one)
  def prepare_options_slim(options), do: Noizu.ElixirCore.SlimOptions.slim(prepare_options(options))
  def prepare_options(options) do


    default_restart_type = (Application.get_env(:noizu_advanced_pool, :worker_pool_restart_type, nil)
                            || Application.get_env(:noizu_advanced_pool, :restart_type, :permanent))

    default_max_restarts = (Application.get_env(:noizu_advanced_pool, :worker_pool_max_restarts, nil)
                            || Application.get_env(:noizu_advanced_pool, :max_restarts, @default_max_restarts))

    default_max_seconds = (Application.get_env(:noizu_advanced_pool, :worker_pool_max_seconds, nil)
                           || Application.get_env(:noizu_advanced_pool, :max_seconds, @default_max_seconds))

    default_strategy = (Application.get_env(:noizu_advanced_pool, :worker_pool_strategy, nil)
                        || Application.get_env(:noizu_advanced_pool, :pool_strategy, @default_strategy))


    default_layer2_restart_type = (Application.get_env(:noizu_advanced_pool, :worker_pool_layer2_restart_type, nil)
                                   || Application.get_env(:noizu_advanced_pool, :worker_pool_restart_type, nil)
                                   || Application.get_env(:noizu_advanced_pool, :restart_type, :permanent))

    default_layer2_max_restarts = (Application.get_env(:noizu_advanced_pool, :worker_pool_layer2_max_restarts, nil)
                                   || Application.get_env(:noizu_advanced_pool, :worker_pool_max_restarts, nil)
                                   || Application.get_env(:noizu_advanced_pool, :max_restarts, @default_max_restarts))

    default_layer2_max_seconds = (Application.get_env(:noizu_advanced_pool, :worker_pool_layer2_max_seconds, nil)
                                  || Application.get_env(:noizu_advanced_pool, :worker_pool_max_seconds, nil)
                                  || Application.get_env(:noizu_advanced_pool, :max_seconds, @default_max_seconds))

    default_layer2_provider = Noizu.AdvancedPool.V3.WorkerSupervisor.Layer2Behaviour

    default_max_supervisors = 100

    settings = %OptionSettings{
      option_settings: %{
        verbose: %OptionValue{option: :verbose, default: :auto},
        restart_type: %OptionValue{option: :restart_type, default: default_restart_type},
        max_restarts: %OptionValue{option: :max_restarts, default: default_max_restarts},
        max_seconds: %OptionValue{option: :max_seconds, default: default_max_seconds},
        strategy: %OptionValue{option: :strategy, default: default_strategy},

        dynamic_supervisor: %OptionValue{option: :dynamic_supervisor, default: false, required: false},

        max_supervisors: %OptionValue{option: :max_supervisors, default: default_max_supervisors},

        layer2_restart_type: %OptionValue{option: :layer2_restart_type, default: default_layer2_restart_type},
        layer2_max_restarts: %OptionValue{option: :layer2_max_restarts, default: default_layer2_max_restarts},
        layer2_max_seconds: %OptionValue{option: :layer2_max_seconds, default: default_layer2_max_seconds},
        layer2_provider: %OptionValue{option: :layer2_provider, default: default_layer2_provider},
      }
    }
    OptionSettings.expand(settings, options)
  end


  def meta_init(module) do
    options = module.options()
    max_supervisors = options.max_supervisors

    leading = round(:math.floor(:math.log10(max_supervisors))) + 1
    supervisor_by_index = Enum.map(1 .. max_supervisors, fn(i) ->
      {i, Module.concat(module, "Seg#{String.pad_leading("#{i}", leading, "0")}")}
    end) |> Map.new()
    available_supervisors = Map.values(supervisor_by_index)
    active_supervisors = length(available_supervisors)
    dynamic_supervisor = options.dynamic_supervisor
    settings = %{
      active_supervisors: active_supervisors,
      available_supervisors: available_supervisors,
      supervisor_by_index: supervisor_by_index,
      dynamic_supervisor: dynamic_supervisor,
    }
    parent_settings = Noizu.AdvancedPool.SettingsBehaviour.Default.meta_init(module, %{})
    Map.merge(parent_settings, settings)
  end






  def group_children(module, group_fn) do
    Task.async_stream(module.available_supervisors(), fn(s) ->
                                                        children = Supervisor.which_children(s)
                                                        sg = Enum.reduce(children, %{}, fn(worker, acc) ->
                                                                                          g = group_fn.(worker)
                                                                                          if g do
                                                                                            update_in(acc, [g], &((&1 || 0) + 1))
                                                                                          else
                                                                                            acc
                                                                                          end
                                                        end)
                                                        {s, sg}
    end, timeout: 60_000, ordered: false)
    |> Enum.reduce(%{total: %{}}, fn(outcome, acc) ->
      case outcome do
        {:ok, {s, sg}} ->
          total = Enum.reduce(sg, acc.total, fn({g, c}, a) ->  update_in(a, [g], &((&1 || 0) ++ c)) end)
          _acc = acc
                 |> put_in([s], sg)
                 |> put_in([:total], total)
        _ -> acc
      end
    end)
  end

  def count_children(module) do
    {a,s, u, w} = Task.async_stream(
                    module.available_supervisors(),
                    fn(s) ->
                      try do
                        u = Supervisor.count_children(s)
                        {u.active, u.specs, u.supervisors, u.workers}
                      catch :exit, _ -> :error
                      end
                    end,
                    [ordered: false, timeout: 60_000, on_timeout: :kill_task]
                  ) |> Enum.reduce({0,0,0,0}, fn(x, {acc_a, acc_s, acc_u, acc_w}) ->
      case x do
        {:ok, {a,s, u, w}} -> {acc_a + a, acc_s + s, acc_u + u, acc_w + w}
        {:exit, :timeout} -> {acc_a, acc_s, acc_u, acc_w}
        _ -> {acc_a, acc_s, acc_u, acc_w}
      end
    end)
    %{active: a, specs: s, supervisors: u, workers: w}
  end

  def current_supervisor(module, ref) do
    cond do
      module.meta()[:dynamic_supervisor] -> current_supervisor_dynamic(module, ref)
      true -> current_supervisor_default(module, ref)
    end
  end

  def current_supervisor_default(module, ref) do
    num_supervisors = module.active_supervisors()
    if num_supervisors == 1 do
      module.supervisor_by_index(1)
    else
      hint = module.pool_worker_state_entity().supervisor_hint(ref)
      pick = rem(hint, num_supervisors) + 1
      module.supervisor_by_index(pick)
    end
  end

  def current_supervisor_dynamic(module, _ref) do
    num_supervisors = module.active_supervisors()
    if num_supervisors == 1 do
      module.supervisor_by_index(1)
    else
      # hint = module.pool_worker_state_entity().supervisor_hint(ref)
      # The logic is designed so that the selected supervisor only changes for a subset of items when adding new supervisors
      # So that, for example, when going from 5 to 6 supervisors only a 6th of entries will be re-assigned to the new bucket.
      pick = fn(hint, num_supervisors) ->
        Enum.reduce_while(num_supervisors .. 1, 1, fn(x, acc) ->
          n = rem(hint, x) + 1
          cond do
            n == x -> {:halt, n}
            true -> {:cont, acc}
          end
        end)
      end
      module.supervisor_by_index(pick)
    end
  end



  def worker_start(module, ref, transfer_state, context) do
    worker_sup = module.current_supervisor(ref)
    childSpec = worker_sup.child(ref, transfer_state, context)
    case Supervisor.start_child(worker_sup, childSpec) do
      {:ok, pid} -> {:ack, pid}
      {:error, {:already_started, pid}} ->
        #timeout = 60_000 #@timeout
        call = {:transfer_state, {:state, transfer_state, time: :os.system_time(:second)}}
        extended_call = module.pool_server().router().extended_call(:s_call!, ref, call, context, %{}, nil)
        #if @s_redirect_feature, do: {:s_call!, {__MODULE__, ref, timeout}, {:s, call, context}}, else: {:s, call, context}
        GenServer.cast(pid, extended_call)
        Logger.warn(fn -> {"#{module} attempted a worker_transfer on an already running instance. #{inspect ref} -> #{inspect node()}@#{inspect pid}", Noizu.ElixirCore.CallingContext.metadata(context)} end)
        {:ack, pid}

      {:error, {{:already_started, pid}, _}} ->
        #timeout = 60_000 #@timeout
        call = {:transfer_state, {:state, transfer_state, time: :os.system_time(:second)}}
        extended_call = module.pool_server().router().extended_call(:s_call!, ref, call, context, %{}, nil)
        #if @s_redirect_feature, do: {:s_call!, {__MODULE__, ref, timeout}, {:s, call, context}}, else: {:s, call, context}
        GenServer.cast(pid, extended_call)
        Logger.warn(fn -> {"#{module} attempted a worker_transfer on an already running instance. #{inspect ref} -> #{inspect node()}@#{inspect pid}", Noizu.ElixirCore.CallingContext.metadata(context)} end)
        {:ack, pid}

      {:error, :already_present} ->
        # We may no longer simply restart child as it may have been initilized
        # With transfer_state and must be restarted with the correct context.
        Supervisor.delete_child(worker_sup, ref)
        case Supervisor.start_child(worker_sup, childSpec) do
          {:ok, pid} -> {:ack, pid}
          {:error, {:already_started, pid}} -> {:ack, pid}
          {:error, {{:already_started, pid}, _}} -> {:ack, pid}
          error -> error
        end
      error -> error
    end # end case
  end

  def worker_start(module, ref, context) do
    worker_sup = module.current_supervisor(ref)
    childSpec = worker_sup.child(ref, context)
    case Supervisor.start_child(worker_sup, childSpec) do
      {:ok, pid} -> {:ack, pid}
      {:error, {:already_started, pid}} -> {:ack, pid}
      {:error, {{:already_started, pid}, _}} -> {:ack, pid}
      {:error, :already_present} ->
        # We may no longer simply restart child as it may have been initialized
        # With transfer_state and must be restarted with the correct context.
        Supervisor.delete_child(worker_sup, ref)
        case Supervisor.start_child(worker_sup, childSpec) do
          {:ok, pid} -> {:ack, pid}
          {:error, {:already_started, pid}} -> {:ack, pid}
          {:error, {{:already_started, pid}, _}} -> {:ack, pid}
          error -> error
        end
      error ->
        Logger.warn fn -> "Worker Start Error #{module}.worker_start(#{inspect ref}) -> #{inspect error}" end
        error
    end # end case
  end
end
