#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

# @todo should be renamed Default and moved into behaviour definition for consistency.
defmodule Noizu.AdvancedPool.V3.WorkerManagement.WorkerManagementProvider do
  require Logger

  @doc """
  Count children of all worker supervisors.
  """
  def count_supervisor_children(pool_server), do: pool_server.pool_worker_supervisor().count_children()

  @doc """
  Group supervisor children by user provided method.
  """
  def group_supervisor_children(pool_server, group_fn), do: pool_server.pool_worker_supervisor().group_children(group_fn)

  @doc """
   Get number of active worker supervisors.
  """
  def active_supervisors(pool_server), do: pool_server.pool_worker_supervisor().active_supervisors()

  @doc """
   Get a supervisor module by index position.
  """
  def supervisor_by_index(pool_server, index), do:  pool_server.pool_worker_supervisor().supervisor_by_index(index)

  @doc """
    Return list of available worker supervisors.
  """
  def available_supervisors(pool_server), do: pool_server.pool_worker_supervisor().available_supervisors()

  @doc """
   Return supervisor responsible for a specific worker.
  """
  def current_supervisor(pool_server, ref), do: pool_server.pool_worker_supervisor().current_supervisor(ref)

  @doc """
  Start worker with transfer.
  @note was worker_sup_start
  """
  def worker_start(pool_server, ref, transfer_state, context), do: pool_server.pool_worker_supervisor().worker_start(ref, transfer_state, context)

  @doc """
  Start worker.
  @note was worker_sup_start
  """
  def worker_start(pool_server, ref, context), do: pool_server.pool_worker_supervisor().worker_start(ref, context)

  @doc """
  Terminate worker.
  @note was worker_sup_terminate
  """
  def worker_terminate(pool_server, ref, context, options \\ %{}), do: pool_server.pool_worker_supervisor().worker_terminate(ref, context, options)

  @doc """
  Remove worker.
  @note was worker_sup_remove
  """
  def worker_remove(pool_server, ref, context, options \\ %{}), do: pool_server.pool_worker_supervisor().worker_remove(ref, context, options)

  @doc """
  Add worker to service.
  """
  def worker_add!(pool_server, ref, context \\ nil, options \\ %{}), do: pool_server.pool_worker_supervisor().worker_add!(ref, context || Noizu.ElixirCore.CallingContext.system(), options)

  @doc """
  Bulk migrate workers.
  """
  def bulk_migrate!(_pool_server, _transfer_server, _context, _options), do: throw :pri0_bulk_migrate!

  @doc """
  Migrate worker.
  """
  def migrate!(pool_server, ref, rebase, context \\ nil, options \\ %{}) do
    context = context || Noizu.ElixirCore.CallingContext.system()
    if options[:sync] do
      pool_server.router().s_call!(ref, {:migrate!, ref, rebase, options}, context, options, options[:timeout] || 60_000)
    else
      pool_server.router().s_cast!(ref, {:migrate!, ref, rebase, options}, context)
    end
  end

  @doc """
  Load worker
  """
  def worker_load!(pool_server, ref, context \\ nil, options \\ %{}), do: pool_server.router().s_cast!(ref, {:load, options}, context ||  Noizu.ElixirCore.CallingContext.system())

  @doc """
  Get worker Ref
  """
  def worker_ref!(pool_server, identifier, _context \\ nil), do: pool_server.__worker_state_entity__().ref(identifier)

  @doc """
  Terminate Worker.
  """
  def terminate!(pool_server, ref, context, options) do
    pool_server.router().run_on_host(ref, {pool_server.worker_management(), :r_terminate!, [ref, context, options]}, context, options)
  end

  @doc """
  terminate method executed on service node.
  """
  def r_terminate!(pool_server, ref, context, options) do
    options_b = put_in(options, [:lock], %{type: :reap, for: 60})
    case pool_server.worker_management().obtain_lock!(ref, context, options_b) do
      {:ack, _lock} -> pool_server.worker_management().worker_terminate(ref, context, options_b)
      o -> o
    end
  end


  @doc """
  Remove worker.
  """
  def remove!(pool_server, ref, context, options) do
    pool_server.router().run_on_host(ref, {pool_server.worker_management(), :r_remove!, [ref, context, options]}, context, options)
  end

  @doc """
  remove method executed on service node.
  """
  def r_remove!(pool_server, ref, context, options) do
    options_b = put_in(options, [:lock], %{type: :reap, for: 60})
    case pool_server.worker_management().obtain_lock!(ref, context, options_b) do
      {:ack, _lock} -> pool_server.worker_management().worker_remove(ref, context, options_b)
      o -> o
    end
  end

  @doc """
  Accept worker transfer to new service node.
  """
  def accept_transfer!(pool_server, ref, state, context \\ nil, options \\ %{}) do
    options_b = options
                |> put_in([:lock], %{type: :transfer})
    case pool_server.worker_management().obtain_lock!(ref, context, options_b) do
      {:ack, _lock} ->
        case pool_server.worker_management().worker_start(ref, state, context) do
          {:ack, pid} ->
            {:ack, pid}
          o -> {:error, {:worker_start, o}}
        end
      o -> {:error, {:get_lock, o}}
    end
  end

  @doc """
  Lock service node from accepting more workers.
  """
  def lock!(pool_server, context, options \\ %{}), do: pool_server.router().internal_system_call({:lock!, options}, context, options)

  @doc """
  Release service node to resume processing new workers.
  """
  def release!(pool_server, context, options \\ %{}), do: pool_server.router().internal_system_call({:release!, options}, context, options)

  # @todo we should tweak function signatures for workers! method.
  @doc """
  Obtain service workers.
  """
  def workers!(pool_server, %Noizu.ElixirCore.CallingContext{} = context), do: workers!(pool_server, node(), pool_server.pool_worker_state_entity(), context, %{})

  def workers!(pool_server, %Noizu.ElixirCore.CallingContext{} = context, options), do: workers!(pool_server, node(), pool_server.pool_worker_state_entity(), context, options)

  def workers!(pool_server, host, %Noizu.ElixirCore.CallingContext{} = context), do: workers!(pool_server, host, pool_server.pool_worker_state_entity(), context, %{})

  def workers!(pool_server, host, %Noizu.ElixirCore.CallingContext{} = context, options), do: workers!(pool_server, host, pool_server.pool_worker_state_entity(), context, options)

  def workers!(pool_server, host, service_entity, %Noizu.ElixirCore.CallingContext{} = context), do: workers!(pool_server, host, service_entity, context, %{})

  def workers!(pool_server, host, service_entity, %Noizu.ElixirCore.CallingContext{} = _context, _options) do
    if dispatch_schema_online?(pool_server) do
      v = pool_server.pool_dispatch_table().match!([identifier: {:ref, service_entity, :_}, server: host])
          |> Amnesia.Selection.values
      {:ack, v}
    else
      {:nack, []}
    end
  end

  @doc """
  Get dispatch record for ref.
  """
  def dispatch_get!(ref, pool_server, _context, _options) do
    record = pool_server.pool_dispatch_table().read!(ref)
    record && record.entity
  end

  @doc """
  Prepare new dispatch
  """
  def dispatch_new(ref, pool_server, _context, options) do
    state = options[:state] || :new
    server = options[:server] || :pending
    lock = dispatch_prepare_lock(pool_server, options)

    # @TODO use raw tuple for smaller table, faster execution.
    %Noizu.AdvancedPool.DispatchEntity{identifier: ref, server: server, state: state, lock: lock}
  end

  @doc """
  Create new dispatch record
  """
  def dispatch_create!(dispatch, pool_server, _context, _options) do
    record = %{__struct__: pool_server.pool_dispatch_table(), entity: dispatch, server: dispatch.server, identifier: dispatch.identifier}
    r = pool_server.pool_dispatch_table().write!(record)
    r.entity
  end

  @doc """
  Update dispatch record.
  """
  def dispatch_update!(dispatch, pool_server, _context, _options) do
    record = %{__struct__: pool_server.pool_dispatch_table(), entity: dispatch, server: dispatch.server, identifier: dispatch.identifier}
    r = pool_server.pool_dispatch_table().write!(record)
    r.entity
  end

  @doc """
  Prepare dispatch lock.
  """
  def dispatch_prepare_lock(_pool_server, options, force \\ false) do
    if options[:lock] || force do
      time = options[:time] || :os.system_time()
      lock_server = options[:lock][:server] || node()
      lock_process = options[:lock][:process] || self()
      lock_until = (options[:lock][:until]) || (options[:lock][:for] && :os.system_time(:seconds) + options[:lock][:for]) || (time + 5 + :rand.uniform(15))
      lock_type = options[:lock][:type] || :spawn
      {{lock_server, lock_process}, lock_type, lock_until}
    else
      nil
    end
  end

  @doc """
  Check if dispatch schema is online.
  """
  def dispatch_schema_online?(pool_server) do
    # TODO use meta, don't continuously check table state.
    case Amnesia.Table.wait([pool_server.pool_dispatch_table()], 5) do
      :ok -> true
      _ -> false
    end
  end

  @doc """
  Obtain dispatch lock.
  """
  def dispatch_obtain_lock!(ref, pool_server, context, options) do
    if dispatch_schema_online?(pool_server) do
      lock = {{lock_server, lock_process}, _lock_type, _lock_until} = dispatch_prepare_lock(pool_server, options, true)
      #record = pool_server.pool_dispatch_table().read!(ref)
      #entity = record && record.entity
      entity = dispatch_get!(ref, pool_server, context, options)
      time = options[:time] || :os.system_time()
      if entity do
        case entity.lock do
          nil -> {:ack, put_in(entity, [Access.key(:lock)], lock) |> dispatch_update!(pool_server, context, options)}
          {{s,p}, _lt, lu} ->
            cond do
              options[:force] -> {:ack, put_in(entity, [Access.key(:lock)], lock) |> dispatch_update!(pool_server, context, options)}
              time > lu -> {:ack, put_in(entity, [Access.key(:lock)], lock) |> dispatch_update!(pool_server, context, options)}
              s == lock_server and p == lock_process -> {:ack, put_in(entity, [Access.key(:lock)], lock) |> dispatch_update!(pool_server, context, options)}
              options[:conditional_checkout] ->
                check = case options[:conditional_checkout] do
                  v when is_function(v) -> v.(entity)
                  {m,f,1} -> apply(m, f, [entity])
                  _ -> false
                end
                if check do
                  {:ack, put_in(entity, [Access.key(:lock)], lock) |> dispatch_update!(pool_server, context, options)}
                else
                  {:nack, {:locked, entity}}
                end
              true -> {:nack, {:locked, entity}}
            end
          _o -> {:nack, {:invalid, entity}}
        end
      else
        e = dispatch_new(ref, pool_server, context, options)
            |> put_in([Access.key(:lock)], lock)
            |> dispatch_create!(pool_server, context, options)
        {:ack, e}
      end
    else
      {:nack, {:error, :schema_offline}}
    end
  end

  @doc """
  Release dispatch lock.
  """
  def dispatch_release_lock!(ref, pool_server, context, options) do
    if dispatch_schema_online?(pool_server) do
      time = options[:time] || :os.system_time()
      entity = dispatch_get!(ref, pool_server, context, options)
      if entity do
        case entity.lock do
          nil -> {:ack, entity}
          {{s,p}, lt, lu} ->
            _lock = {{lock_server, lock_process}, lock_type, _lock_until} = dispatch_prepare_lock(pool_server, options, true)
            cond do
              options[:force] ->
                {:ack, put_in(entity, [Access.key(:lock)], nil) |> dispatch_update!(pool_server, context, options)}
              time > lu ->
                {:ack, put_in(entity, [Access.key(:lock)], nil) |> dispatch_update!(pool_server, context, options)}
              s == lock_server and p == lock_process and lt == lock_type -> {:ack, put_in(entity, [Access.key(:lock)], nil) |> dispatch_update!(pool_server, context, options)}
              true -> {:nack, {:not_owned, entity}}
            end
        end
      else
        {:ack, nil}
      end
    else
      {:nack, {:error, :schema_offline}}
    end
  end

  @doc """
  Obtain host of worker.
  """
  def host!(pool_server, ref, context, options \\ %{spawn: true}) do
    # @TODO load from meta or pool.options
    sm = pool_server.__service_manager__()

    case dispatch_get!(ref, pool_server, context, options) do
      nil ->
        if options[:spawn] do
          options_b = update_in(options, [:lock], &(Map.merge(&1 || %{}, %{server: :pending, type: :spawn})))
          entity = dispatch_new(ref, pool_server, context, options_b)
                   |> put_in([Access.key(:lock)], dispatch_prepare_lock(pool_server, options_b, true))
                   |> dispatch_create!(pool_server,context, options_b)

          case sm.select_host(pool_server.pool(), ref, context, options_b) do
            {:ack, host} ->
              entity = entity
                       |> put_in([Access.key(:server)], host)
                       |> put_in([Access.key(:lock)], nil)
                       |> dispatch_update!(pool_server, context, options_b)
              {:ack, entity.server}
            {:nack, details} ->
              _entity = entity
                        |> put_in([Access.key(:lock)], nil)
                        |> dispatch_update!(pool_server, context, options_b)
              {:error, {:host_pick, {:nack, details}}}
            o ->
              o
          end
        else
          {:nack, :no_registered_host}
        end
      v when is_atom(v) -> {:error, {:repo, v}}
      {:error, details} -> {:error, details}
      entity ->
        if entity.server == :pending do
          options_b = update_in(options, [:lock], &(Map.merge(&1 || %{}, %{server: :pending, type: :spawn})))
          if options[:dirty] do
            case sm.select_host(pool_server.pool(), ref, context, options_b) do
              {:ack, host} ->
                entity = entity
                         |> put_in([Access.key(:server)], host)
                         |> put_in([Access.key(:lock)], nil)
                         |> dispatch_update!(pool_server, context, options_b)
                {:ack, entity.server}
              {:nack, details} -> {:error, {:host_pick, {:nack, details}}}
              o -> o
            end
          else
            case dispatch_obtain_lock!(ref, pool_server, context, options_b) do
              {:ack, lock} ->
                case sm.select_host(pool_server.pool(), ref, context, options_b) do
                  {:ack, host} ->
                    entity = lock
                             |> put_in([Access.key(:server)], host)
                             |> put_in([Access.key(:lock)], nil)
                             |> dispatch_update!(pool_server, context, options_b)
                    {:ack, entity.server}
                  {:nack, details} -> {:error, {:host_pick, {:nack, details}}}
                  o -> o
                end
              {:nack, details} -> {:error, {:obtain_lock, {:nack, details}}}
            end
          end
        else
          {:ack, entity.server}
        end
    end
  end

  @doc """
  Record worker event.
  """
  def record_event!(_pool_server, _ref, _event, _details, context, _options \\ %{}) do
    Logger.warn("[V2] New record_event!() Implementation Needed", Noizu.ElixirCore.CallingContext.metadata(context))
    :wip
  end

  @doc """
  Obtain worker events.
  """
  def events!(_pool_server, _ref, context, _options \\ %{}) do
    Logger.warn("[V2] New events!() Implementation Needed", Noizu.ElixirCore.CallingContext.metadata(context))
    []
  end

  @doc """
  Set dispatch node for ref.
  """
  def set_node!(pool_server, ref, context, options \\ %{}) do
    #Logger.warn("[V2] New set_node!() Implementation Needed")
    wm = pool_server.worker_management()

    Task.async(fn ->
      case dispatch_get!(ref, pool_server, context, options) do
        nil -> :unexpected
        entity ->
          if entity.server != node() do
            entity
            |> put_in([Access.key(:server)], node()) #@TODO standardize naming conventions.
            |> dispatch_update!(pool_server, context, options)
          end
      end

      inner = Task.async(fn ->
        # TODO consider using semaphore library.
        # delay before releasing lock to allow a flood of node updates to update before removing locks.
        Process.sleep(60_000)
        # Release lock off main thread
        options_b = %{lock: %{type: :init}, conditional_checkout: fn(x) ->
          case x do
            %{lock: {{_s, _p}, :transfer, _t}} -> true
            %{lock: {{_s, _p}, :spawn, _t}} -> true
            %{lock: {{_s, _p}, :init, _t}} -> true
            _ -> false
          end
        end}
        options_b = Map.merge(options_b, options)
        {:ack, wm.release_lock!(ref, context, options_b)}
      end)
      {:ack, inner}
    end)
  end

  @doc """
  Register worker pid.
  """
  def register!(pool_server, ref, _context, _options \\ %{}) do
    #Logger.warn("[V2] New register!() Implementation Needed")
    Registry.register(pool_server.__registry__(), {:worker, ref}, :process)
  end

  @doc """
  Unregister worker pid.
  """
  def unregister!(pool_server, ref, _context, _options \\ %{}) do
    #Logger.warn("[V2] New unregister!() Implementation Needed")

    #Registry.unregister(pool_server.pool_registry(), ref)
    Registry.unregister(pool_server.__registry__(), {:worker, ref})
  end

  @doc """
  Obtain dispatch lock for ref.
  """
  def obtain_lock!(pool_server, ref, context, options \\ %{}) do
    #Logger.warn("[V2] New obtain_lock!() Implementation Needed")

    options_b = update_in(options, [:lock], &(Map.merge(&1 || %{}, %{type: :general})))
    dispatch_obtain_lock!(ref, pool_server, context, options_b)
  end

  @doc """
  Release dispatch lock for ref.
  """
  def release_lock!(pool_server, ref, context, options \\ %{}) do
    dispatch_release_lock!(ref, pool_server, context, options)
  end

  @doc """
  Obtain process of ref.
  """
  def process!(pool_server, ref, context, options \\ %{}) do
    #Logger.warn("[V2] New process!() Implementation Needed")

    # @TODO load from meta or pool.options
    server = pool_server
    #base = pool_server.pool()
    wm = pool_server.__worker_management__()
    r = pool_server.__registry__()

    record = options[:dispatch_record] || dispatch_get!(ref, pool_server, context, options)

    case record do
      nil ->
        case wm.host!(ref, context, options) do
          {:ack, host} ->
            if host == node() do
              case Registry.lookup(r, {:worker, ref}) do
                [] ->
                  if options[:spawn] do
                    if options[:dirty] do
                      case server.__worker_management__().worker_start(ref, context) do
                        {:ok, pid} -> {:ack, pid}
                        {:ack, pid} -> {:ack, pid}
                        o -> o
                      end
                    else
                      options_b = %{lock: %{type: :init}, conditional_checkout: fn(x) ->
                        case x.lock do
                          {{_s, _p}, :spawn, _t} -> true
                          _ -> false
                        end
                      end}
                      case wm.obtain_lock!(ref, context, options_b) do
                        {:ack, _lock} ->
                          case server.__worker_management__().worker_start(ref, context) do
                            {:ok, pid} -> {:ack, pid}
                            {:ack, pid} -> {:ack, pid}
                            o -> o
                          end
                        o -> o
                      end
                    end
                  else
                    {:nack, :not_registered}
                  end
                [{pid, _v}] -> {:ack, pid}
                v ->
                  #@PRI-0 disabled until rate limite added - mod.record_event!(ref, :registry_lookup_fail, v, context, options)
                  {:error, {:unexpected_response, v}}
              end
            else
              options_b = put_in(options, [:dispatch_record], record)
              case :rpc.call(host, wm, :process!, [ref, context, options_b], 5_000) do
                {:ack, process} -> {:ack, process}
                {:nack, details} -> {:nack, details}
                {:error, details} -> {:error, details}
                {:badrpc, details} ->
                  #@PRI-0 disabled until rate limite added - mod.record_event!(ref, :process_check_fail, {:badrpc, details}, context, options)
                  {:error, {:badrpc, details}}
                o -> {:error, o}
              end
            end

          v -> {:nack, {:host_error, v}}
        end

      %{server: host} ->
        cond do
          host == :pending ->
            if options[:spawn] do
              host2 = wm.host!(ref, context, options)
              if host2 == node() do
                options_b = %{lock: %{type: :init}, conditional_checkout: fn(x) ->
                  case x do
                    %{lock: {{_s, _p}, :spawn, _t}} -> true
                    _ -> false
                  end
                end}
                case wm.obtain_lock!(ref, context, options_b) do
                  {:ack, _lock} ->
                    case server.__worker_management__().worker_start(ref, context) do
                      {:ok, pid} -> {:ack, pid}
                      {:ack, pid} -> {:ack, pid}
                      o -> o
                    end
                  o -> o
                end
              else
                :rpc.call(host2, wm, :process!, [ref, context, options], 5_000)
              end
            else
              {:nack, :not_registered}
            end
          host == node() ->
            #IO.puts "++++++++++++++++++++++++++++++ Calling Registry Lookup"
            #IO.puts "++++++++++++++++++++++++++++++ Calling Registry Lookup #{inspect {r, {:worker, ref} }}"
            #IO.puts "++++++++++++++++++++++++++++++ Calling Registry Lookup #{inspect Registry.lookup(r, {:worker, ref})}"

            case Registry.lookup(r, {:worker, ref}) do
              [] ->
                if options[:spawn] do
                  options_b = %{lock: %{type: :init}, conditional_checkout: fn(x) ->
                    case x do
                      %{lock: {{_s, _p}, :spawn, _t}} -> true
                      _ -> false
                    end
                  end}
                  case wm.obtain_lock!(ref, context, options_b) do
                    {:ack, _lock} ->
                      case server.__worker_management__().worker_start(ref, context) do
                        {:ok, pid} -> {:ack, pid}
                        {:ack, pid} -> {:ack, pid}
                        o -> o
                      end
                    o -> o
                  end
                else
                  {:nack, :not_registered}
                end
              [{pid, _v}] -> {:ack, pid}
              v ->
                #@PRI-0 disabled until rate limite added - mod.record_event!(ref, :registry_lookup_fail, v, context, options)
                {:error, {:unexpected_response, v}}
            end
          true ->
            options_b = put_in(options, [:dispatch_record], record)
            timeout = options_b[:timeout] || 30_000
            case :rpc.call(host, wm, :process!, [ref, context, options_b], timeout) do
              {:ack, process} -> {:ack, process}
              {:nack, details} -> {:nack, details}
              {:error, details} -> {:error, details}
              {:badrpc, details} ->
                #@PRI-0 disabled until rate limite added - mod.record_event!(ref, :process_check_fail, {:badrpc, details}, context, options)
                {:error, {:badrpc, details}}
              o -> {:error, o}
            end
        end
    end

  end

end
