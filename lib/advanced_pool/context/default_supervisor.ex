defmodule Noizu.AdvancedPool.DefaultSupervisor do
  @moduledoc """
  Defines the default supervisor for `Noizu.AdvancedPool`, responsible for initiating and managing
  a supervisor hierarchy within a pool of workers. The `DefaultSupervisor` serves as the top-level
  supervisor for the pool, capable of configuring its children supervisors and servers based on the
  applicable context and options.

  It leverages the configuration provided by developers for custom behaviors, while also providing
  default settings for different strategies pertaining to supervision and worker management.
  The supervisor is crucial for maintaining the fault tolerance of the pool by overseeing the
  behavior of supervisors that manage individual worker processes.

  When launched, it ensures that the supervisory process joins the appropriate cluster and sets up
  the related server and workers accordingly. It can operate both in standalone mode and as part of
  a clustered environment, adjusting its behavior based on the configuration.
  """

  use Supervisor
  require Logger
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message

  @doc """
  Starts the default supervisor with a unique identifier, utilizing the provided pool module and context to
  configure the supervisor's behavior. It will use either the configured supervisor module or default to
  itself when starting the supervisor process.

  The `start_link/4` pattern integrates the pool into the OTP supervision structure, linking it to the top-level
  supervisor and ensuring that it adheres to the predefined supervision strategies. The identity and name of
  the supervisor are derived based on the pool's id or directly from the pool itself.

  This function serves as the entry point for creating the pool's supervisory tree and integrating it into
  the running application's supervision hierarchy.
  """
  def start_link(id, pool, context, options) do
    supervisor = apply(pool, :config, [])[:otp][:supervisor] || __MODULE__

    Logger.info("""
    INIT #{__MODULE__}#{inspect __ENV__.function}
    ***************************************
    #{inspect({id, pool, context, options})}

    #{inspect supervisor}

    """)


    Supervisor.start_link(supervisor, {id, pool, context, options}, name: id) |> tap(& Logger.info("#{__MODULE__}#{inspect __ENV__.function} #{inspect &1}"))
  end

  def terminate(reason, state) do
    Logger.error("""
    TERMINATE #{__MODULE__}#{inspect __ENV__.function}
    ***************************************
    #{inspect({reason, state})}
    """)
    :ok
  end

  @doc """
  Sets a default target for the maximum number of worker processes a supervisor should manage.
  This default target acts as a threshold to inform scaling and spawning decisions within the pool.

  By providing a predetermined target, `default_worker_target/0` simplifies configuration by establishing an
  inferred baseline that can be overridden with specific demands as needed. It ensures that there is an out-of-the-box
  value for immediate use, promoting a quick setup while maintaining flexibility for adaptation.
  """
  def default_worker_target(), do: 50_000



  @doc """
  Initializes the supervisor with the provided configuration, determining if it should operate in standalone mode
  or join a cluster. Depending on the mode, it sets up its child processes, including servers and worker supervisors.

  The `init/1` function orchestrates the bootstrapping of the supervisory tree according to the pool's configuration.
  It sets the supervision strategy and delegates to subcomponents like servers and worker supervisors to create a
  cohesive structure that ensures the pool's operational integrity.
  """
  def init({_id, pool, context, options}) do
    Logger.info("""
    INIT #{__MODULE__}#{inspect __ENV__.function}
    ***************************************


    """)

    # Setup Worker Event Tracker
    with [] <- :ets.lookup(:worker_events, {:service, pool}) do
      entry = worker_events(refreshed_on: :os.system_time(:millisecond)) |> put_in([Access.elem(0), Access.elem(1)], pool)
      :ets.insert(:worker_events, entry)
    end

    apply(pool, :join_cluster, [self(), context, options])
    cond do
      apply(pool, :config, [])[:stand_alone] ->
        [
          {Task.Supervisor, name: apply(pool, :__task_supervisor__, [])},
          apply(pool, :__server__, []) |> apply(:server_spec, [context, options])
        ]
      :else ->
        [
          {Task.Supervisor, name: apply(pool, :__task_supervisor__, [])},
          apply(pool, :__server__, []) |> apply(:server_spec, [context, options]),
          apply(pool, :__worker_supervisor__, []) |> apply(:spec, [:os.system_time(:nanosecond), pool, context, options]),
        ]
    end
    |> Supervisor.init(strategy: :one_for_one)
    |> tap(fn(x) ->

      Logger.info("""
      INIT #{__MODULE__}#{inspect __ENV__.function}
      ***************************************
      #{inspect x}

      """)


    end)
  end


  @doc """
  Compiles the start specification for a supervisor process within the pool. The spec dictates the supervisor's
  module, the function to initiate it, and the parameters required to start it, along with an identifier and name.

  With `spec/2-3`, the developer has a tool to uniformly describe how pool supervisors should be started. This
  specification is an integral part of the OTP supervision model, ensuring a consistent and reliable process
  initialization that adheres to the supervision tree's constraints and strategies.
  """
  def spec(pool, context, options \\ nil) do
    id = options[:id] || pool
    supervisor = apply(pool, :config, [])[:otp][:supervisor] || __MODULE__
    start_params = [id, pool, context, options]
    %{
      id: id,
      name: id,
      type: :supervisor,
      start: {supervisor, :start_link, start_params}
    }
  end


  @doc """
  Adds a new worker supervisor to the designated node within the pool. It utilizes the provided spec to start
  a child process under the respective supervisory structure at the specified node.

  The ability to `add_worker_supervisor/3` is instrumental for scaling out the pool's capacity, enabling the pool
  to dynamically adjust its supervisory bandwidth in response to workload variations and maintaining equilibrium
  in resource consumption across the cluster.
  """
  def add_worker_supervisor(pool, node, spec) do
    Supervisor.start_child({pool, node}, spec)
  end
  
end
