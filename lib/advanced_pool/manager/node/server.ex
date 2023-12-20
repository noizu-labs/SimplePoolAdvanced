defmodule Noizu.AdvancedPool.NodeManager.Server do
  @moduledoc """
  Represents the GenServer responsible for managing state and core functionalities of node management within
  the AdvancedPool framework. It performs essential tasks such as processing health reports, handling
  node-level configurations, and maintaining the node's registry within the pool's ecosystem.

  This server facilitates the health and configuration aspects of the NodeManager module. It is initiated
  as a GenServer and defines the setup and supervision of related processes. Additionally, it integrates
  with the Syn library for process registration and clustering of node information across the pool.

  ## Responsibilities

  The NodeManager.Server is tasked with:
    - Hosting the GenServer processes for node management activities.
    - Initializing the node's configuration and health reporting state.
    - Interacting with the configuration provider to handle node settings.
    - Establishing the initial state of the node registry for tracking and supervision purposes.
    - Being the communication endpoint for node-related synchronous and asynchronous messages and calls.

  This server works in conjunction with the NodeManager.Supervisor and other components of the AdvancedPool
  to support distributed functionality and offer fine-grained control over node operations and registrations.
  """

  use GenServer
  require Record
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  require Logger
  alias Noizu.AdvancedPool.Message.Handle, as: MessageHandler
  
  #===========================================
  # Struct
  #===========================================
  #@pool Noizu.AdvancedPool.NodeManager
  defstruct [
    identifier: nil,
    health_report: nil,
    previous_health_report: nil,
    node_config: [],
    meta: []
  ]

  #===========================================
  # Config
  #===========================================
  def __configuration_provider__(), do: Noizu.AdvancedPool.NodeManager.__configuration_provider__()
  
  #===========================================
  # Server
  #===========================================
  def start_link(context, options) do
    Logger.info("""
    INIT #{__MODULE__}#{inspect __ENV__.function}
    ***************************************


    """)
    GenServer.start_link(__MODULE__, {context, options}, name: __MODULE__)
  end

  def terminate(reason, state) do
    Logger.info("""
    TERMINATE #{__MODULE__}#{inspect __ENV__.function}
    ***************************************
    #{inspect({reason, state})}
    """)
    :ok
  end
  
  def init({context, options}) do
    configuration = (with {:ok, configuration} <-
                            __configuration_provider__()
                            |> Noizu.AdvancedPool.NodeManager.ConfigurationManager.configuration(node()) do
                       configuration
                     else
                       e = {:error, _} -> e
                       error -> {:error, {:invalid_response, error}}
                     end)
    
    init_registry(context, options)
    {:ok, %Noizu.AdvancedPool.NodeManager.Server{identifier: node(), node_config: configuration}}
  end
  
  def spec(context, options \\ nil) do
    %{
      id: __MODULE__,
      type: :worker,
      start: {__MODULE__, :start_link, [context, options]}
    }
  end
  
  #===========================================
  # Registry
  #===========================================
  def init_registry(_, _) do
    ts = :os.system_time(:second)
    status = node_status(node: node(), status: :initilizing, manager_state: :init, health_index: 0.0, started_on: ts, updated_on: ts)
    refresh_registry(self(), status)
  end

  def refresh_registry(pid, status) do
    :syn.register(__pool__(), {:node_manager, node()}, pid, status)
    :syn.join(__pool__(), :node_managers, pid, status)
    apply(__dispatcher__(), :__register__, [__pool__(), {:ref, __MODULE__, node()}, pid, status])
  end
  
  #================================
  # Routing
  #================================
  
  #-----------------------
  #
  #-----------------------
  def handle_call(msg_envelope() = call, from, state) do
    MessageHandler.unpack_call(call, from, state)
  end
  def handle_call(s(call: {:health_report, subscriber}, context: context), _, state) do
    health_report(state, subscriber, context)
  end
  def handle_call(s(call: :configuration, context: context), _, state) do
    configuration(state, context)
  end
  def handle_call(call, from, state), do: MessageHandler.uncaught_call(call, from, state)
  
  #-----------------------
  #
  #-----------------------
  def handle_cast(msg_envelope() = call, state) do
    MessageHandler.unpack_cast(call, state)
  end
  def handle_cast(s(call: {:update_health_report, report}, context: context), state) do
    update_health_report(state, report, context)
  end
  def handle_cast(call, state), do: MessageHandler.uncaught_cast(call, state)
  
  #-----------------------
  #
  #-----------------------
  def handle_info(msg_envelope() = call, state) do
    MessageHandler.unpack_info(call, state)
  end
  def handle_info(call, state), do: MessageHandler.uncaught_info(call, state)


  #================================
  # Behaviour
  #================================
  def __pool__(), do: Noizu.AdvancedPool.NodeManager
  def __server__(), do: Noizu.AdvancedPool.NodeManager.Server
  def __supervisor__(), do: Noizu.AdvancedPool.NodeManager.Supervisor
  def __dispatcher__(), do: apply(__pool__(), :__dispatcher__, [])
  def __registry__(), do: apply(__pool__(), :__registry__, [])

  #================================
  #
  #================================


  Noizu.AdvancedPool.NodeManager.Task
  #================================
  # Methods
  #================================
  

  def health_report(state, subscriber, context, options \\ nil) do
    with true <- !Noizu.AdvancedPool.NodeManager.HealthReport.processing?(state.health_report) || :processing,
         {:ok, state} <- request_health_report(state, subscriber, context, options) do
      {:reply, {:ok, state.previous_health_report || :initializing}, state}
    else
      :processing ->
        update_in(state, [Access.key(:health_report), Access.key(:subscribers)], & subscriber && [subscriber| &1] || &1)
        {:reply, {:ok, state.previous_health_report}, state}
      error = {:error, _} -> {:reply, error, state}
      error -> {:reply, {:error, error}, state}
    end
  end


  #----------------
  # update_health_report/3
  #----------------
  def update_health_report(state, report, _context) do
    health_report = unless state.health_report do
      %Noizu.AdvancedPool.NodeManager.HealthReport{
        worker: nil,
        started_at: DateTime.utc_now(),
        status: :processing,
      }
    else
      state.health_report
    end

    health_report = %Noizu.AdvancedPool.NodeManager.HealthReport{health_report|
      worker: nil,
      finished_at: DateTime.utc_now(),
      report: report,
      status: :ready,
    }

    # Call Config Manager - # todo verify :ok response
    apply(__configuration_provider__(), :report_node_health, [state.identifier, report])

    state = state
            |> put_in([Access.key(:health_report)], health_report)

    Enum.map(health_report.subscribers || [], fn(r) ->
      spawn fn ->
        send(r, {:node_health_report, {state.identifier, health_report}})
      end
    end)

    {:noreply, state}
  end

  #----------------
  # request_health_report/2
  #----------------
  defp request_health_report(state, subscriber, context, options) do
    worker = Task.Supervisor.async_nolink(Noizu.AdvancedPool.NodeManager.Task, __MODULE__, :do_build_health_report, [state.identifier, context, options])
    health_report = %Noizu.AdvancedPool.NodeManager.HealthReport{
      worker: worker,
      subscribers: subscriber && [subscriber] || [],
      status: :processing,
      started_at: DateTime.utc_now(),
    }
    state = state
            |> put_in([Access.key(:previous_health_report)], state.health_report)
            |> put_in([Access.key(:health_report)], health_report)
    {:ok, state}
  end




  #----------------
  # do_build_health_report/1
  #----------------
  def do_build_health_report(node, context, options) do
    context = Noizu.ElixirCore.CallingContext.system(context)
    with {:ok, config} <- Noizu.AdvancedPool.NodeManager.config(node)  do
      r = Enum.map(config,
        fn
          ({service_pool, node_service(state: expected_state, priority: priority, supervisor_target: sup_target, worker_target: worker_target, pool: service_pool, health_target: health_target, node: ^node)}) ->
            accumulator = with [record] <- :ets.lookup(:worker_events_accumulator, {:service, service_pool}) do
              record
            else
              _ ->
                ts = :os.system_time(:millisecond)
                worker_events(started_on: ts, refreshed_on: ts) |> put_in([Access.elem(0), Access.elem(1)], service_pool)
            end

            age = :os.system_time(:millisecond) - worker_events(accumulator, :started_on)

            cond do
              options[:rebuild] || age > (15 * 60 * 1000) ->
                # Get Worker Supervisors.
                # Get WS.count_children



                ts = :os.system_time(:millisecond)
                zero_out = worker_events(started_on: ts, refreshed_on: ts) |> put_in([Access.elem(0), Access.elem(1)], service_pool)
                :ets.insert(:worker_events, worker_events(refreshed_on: ts) |> put_in([Access.elem(0), Access.elem(1)], service_pool))


                {service_pool, :rebuild}
            :else ->

              with [delta] <- :ets.lookup(:worker_events, {:service, service_pool}) do
                ts = :os.system_time(:millisecond)
                :ets.insert(:worker_events, worker_events(refreshed_on: ts) |> put_in([Access.elem(0), Access.elem(1)], service_pool))

                a_started_on = worker_events(accumulator, :started_on)
                a_errors = worker_events(accumulator, :error)
                a_warnings = worker_events(accumulator, :warning)
                a_init = worker_events(accumulator, :init)
                a_terminate = worker_events(accumulator, :terminate)
                a_sup_init = worker_events(accumulator, :sup_init)
                a_sup_terminate = worker_events(accumulator, :sup_terminate)

                d_started_on = worker_events(delta, :started_on)
                d_errors = worker_events(delta, :error)
                d_warnings = worker_events(delta, :warning)
                d_init = worker_events(delta, :init)
                d_terminate = worker_events(delta, :terminate)
                d_sup_init = worker_events(delta, :sup_init)
                d_sup_terminate = worker_events(delta, :sup_terminate)

                # Update accumulator ets record
                updated_accumulator = worker_events(accumulator,
                  refreshed_on: ts,
                  error: a_errors + d_errors,
                  warning: a_warnings + d_warnings,
                  init: a_init + d_init,
                  terminate: a_terminate + d_terminate,
                  sup_init: a_sup_init + d_sup_init,
                  sup_terminate: a_sup_terminate + d_sup_terminate
                ) |> put_in([Access.elem(0), Access.elem(1)], service_pool)
                :ets.insert(:worker_events_accumulator, updated_accumulator)


                # Calculate Health
                # worker_health = (((target - actual) - low) / (high - low))
                w_actual = (a_init + d_init) - (a_terminate + d_terminate)
                target_window(target: w_target, low: w_low, high: w_high) = worker_target
                worker_health = (((w_actual-w_target)) / (w_high - w_low))

                #IO.inspect({worker_health, d_init, d_terminate,  w_actual, w_target - w_actual, w_low, w_high - w_low})
                # Calculate Health (supervisors)
                s_actual = (a_sup_init + d_sup_init) - (a_sup_terminate + d_sup_terminate)
                target_window(target: s_target, low: s_low, high: s_high) = sup_target
                sup_health = (((s_target-s_actual) - s_low) / (s_high - s_low))


                period = ts - a_started_on
                errors_per_second_per_worker = (a_errors + d_errors) * (period/(1_000 * max(w_actual, 1)))
                warnings_per_second_per_worker = (a_warnings + d_warnings) * (period/(1_000 * max(w_actual, 1)))

                # Workers at target is treated as 0 errors per worker per second
                # Workers at capacity is treated as 0.05 errors per worker per second,
                # Workers at double capacity is treated as 0.4 errors per worker per second,
                # Workers at quad capacity are treated as 3.2 errors per worker per second, increasing exponentially^3
                wh = cond do
                  worker_health <= 0 -> 0.0
                  :else -> (worker_health * worker_health * worker_health) * 0.05
                end
                sh = cond do
                  sup_health <= 0 -> 0.0
                  :else -> (sup_health * sup_health * sup_health) * 0.025
                end
                # warnings are treated as 0.1 * errors/ms per worker.
                health = Enum.max([wh, sh, errors_per_second_per_worker, warnings_per_second_per_worker * 0.1])

                # Report
                with {pid, status} <- :syn.lookup(service_pool, {:node, node}) do
                  status = pool_status(status, worker_count: w_actual, health: health)
                  Noizu.AdvancedPool.NodeManager.set_service_status(pid, service_pool, node, status)
                end

                # Generate pool report section
                report = %{
                  health: health,
                  workers: %{
                    total: w_actual,
                    health: worker_health,
                    target: w_target,
                    low: w_low,
                    high: w_high,
                  },
                  worker_supervisors: %{
                    total: s_actual,
                    health: sup_health,
                    target: s_target,
                    low: s_low,
                    high: s_high,
                  },
                  errors_per_second_per_worker: errors_per_second_per_worker,
                  warnings_per_second_per_worker: warnings_per_second_per_worker,
                }
                {service_pool, report}
              end
            end
        end
      ) |> Map.new()

      Noizu.AdvancedPool.NodeManager.update_health_report(node, r, context)

    end

    # rescue/else health_report_error ...
  end

#
#  def health_report(state, subscriber, _context) do
#    pools = with {:ok, services} <- Noizu.AdvancedPool.NodeManager.config(state.identifier) do
#      Enum.map(services, fn {pool, _} ->
#        pool
#      end)
#    end
#    #Logger.error("[TODO #{inspect state.identifier}] walk over all services on this node: [#{inspect pools}]")
#    #Logger.error("...#{inspect :syn.members(Noizu.AdvancedPool.Support.TestPool, {state.identifier, :worker_sups}) }")
#    #Logger.error("...#{inspect :syn.members(Noizu.AdvancedPool.Support.TestPool2, {state.identifier, :worker_sups}) }")
#    #Logger.error("...#{inspect :syn.members(Noizu.AdvancedPool.Support.TestPool3, {state.identifier, :worker_sups}) }")
#    #Logger.error("...#{inspect :syn.members(Noizu.AdvancedPool.Support.TestPool4, {state.identifier, :worker_sups})  }")
#    # [{#PID<0.250.0>, {:worker_sup_status, :offline, Noizu.AdvancedPool.Support.TestPool4, :initializing, :nap_test_member_e@localhost, 0, {:target_window, 2500, 500, 5000}, 1702749304}}]
#    Enum.map(pools,
#      fn(pool) ->
#        with [record] <- :ets.lookup(:worker_events, {:service, pool}) do
#          # todo more complex health value value based on total workers versus worker target
#          c_init = worker_events(record, :init)
#          c_terminate = worker_events(record, :terminate)
#          c = c_init - c_terminate
#          c = if c == 0, do: 1, else: c
#          with {pid, status} <- :syn.lookup(pool, {:node, state.identifier}) do
#            status = pool_status(status, health: 1/(c * 1.0))
#            Noizu.AdvancedPool.NodeManager.set_service_status(pid, pool, state.identifier, status)
#            #IO.puts "UPDATE #{state.identifier}.#{pool} set health = 1 / (#{c_init} - #{c_terminate}) -> #{1 / (c * 1.0)}"
#          end
#        end
#
#    end)
#
#
#    {:reply, :pending_node_report, state}
#  end

  def configuration(state, _context) do
    {:reply, state.node_config, state}
  end
  
end
