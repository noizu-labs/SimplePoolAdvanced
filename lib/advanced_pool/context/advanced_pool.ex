defmodule Noizu.AdvancedPool do
  @moduledoc """
  A high-performance, scalable pool manager, `Noizu.AdvancedPool` is designed to handle the lifecycle
  and communication of a large number of long-lived worker processes across a distributed system.

  With functionalities that span from dynamic worker supervision to direct process interaction, it's capable
  of handling millions of actively managed processes efficiently. The pool manager integrates seamlessly within a
  clustered environment, ensuring that workloads are balanced and resources are optimally utilized.

  By providing various utility functions, the `Noizu.AdvancedPool` simplifies complex tasks such as cluster integration,
  bringing the pool online, adding worker supervisors, and proactive worker management. It also offers a suite of service
  worker hooks that facilitate common interactions with pool workers, like reloading configurations, fetching internal
  states, performing health checks, and managing worker lifecycles.

  The module's architecture encourages customization, allowing developers to define specific behaviors for message handling,
  load distribution, and state persistence which fit their application's needs. The provided `__using__` macro includes default
  implementations and overridable functions, promoting a plug-and-play approach that can be tailored through module configurations.
  """

  require Record
  require Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M
  require Logger
  require Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour
  alias Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour, as: Config

  @doc """
  [INTERNAL]
  `default_worker_sup_target/0` provides a set of target window settings used for supervisory processes when managing
  worker spawning.
  It determines low, target, and high thresholds that guide the decision-making process on when to start new supervisory
  processes for workers.
  The implementation relies on settings from `Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour` to facilitate
  scaling according to best practices.
  The values assist in load balancing and resource utilization across the cluster.
  """
  @internal true
  def default_worker_sup_target() do
    M.target_window(low: 500, target: 2_500, high: 5_000)
  end

  @doc """
  [INTERNAL]
  `default_worker_target/0` defines standard target window settings for worker processes across the cluster.
  These settings include lower, target, and upper limits that help manage the pool's response to worker demand and
  system load.
  The implementation references `Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour` to provide predefined scaling metrics.
  These metrics are crucial to maintaining optimal performance by preemptively scaling the number of worker processes.
  """
  @internal true
  def default_worker_target() do
    M.target_window(low: 10_000, target: 50_000, high: 100_000)
  end


  @doc """
  [INTERNAL]
  `pool_scopes/0` generates an array of OTP component identifiers associated with the current pool.
  Each element in the array corresponds to different components, such as the pool itself, its server, worker supervisors,
  workers, and the registry.
  The function provides a consolidated view of identifiers for easy access and management by internally applying
  respective callbacks on the pool module.
  """
  @internal true
  def pool_scopes(pool) do
    [ pool,
      apply(pool, :__server__, []),
      apply(pool, :__worker_supervisor__, []),
      apply(pool, :__worker__, []),
      apply(pool, :__registry__, [])
    ]
  end

  @doc """
  [INTERNAL]
  `join_cluster/4` enrolls the pool within a cluster environment.
  It takes the pool module, a process identifier, context, and options as parameters to successfully register
  the pool's supervisory process with the cluster manager.
  By invoking `Noizu.AdvancedPool.NodeManager.register_pool/4`, a pool can become a participant in a larger
  networked, gaining benefits such as load distribution and redundancy.
  """
  @internal true
  def join_cluster(pool, pid, context, options) do
    Noizu.AdvancedPool.NodeManager.register_pool(pool, pid, context, options)
  end


  #----------------------------------------
  #
  #----------------------------------------
  @doc """
  `get_direct_link!/4` is used to retrieve a direct communication link to a specific worker within the pool.
  It accepts the pool module, a worker reference, context, and an optional set of options, attempting to locate and validate the worker process.
  If successful, it returns a link struct that includes the worker's node, its process identifier (PID), and the original worker reference.
  This function bypasses indirect message dispatch mechanisms and is crucial for scenarios where direct interaction with a worker is required, improving message routing efficiency and performance.
  In case the worker reference cannot be validated or the worker process cannot be found, it raises an error with detailed information.
  """
  @internal true
  def get_direct_link!(pool, M.ref() = ref, _context, _options \\ nil) do
    worker = apply(pool, :__worker__, [])
    with {:ok, ref} <- apply(worker, :ref_ok, [ref]) do
      with {:ok, {pid, attributes}} <- Noizu.AdvancedPool.DispatcherRouter.__lookup_worker_process__(ref) do
        M.link(node: attributes[:node], process: pid, recipient: ref)
      else
        _ ->
          M.link(node: nil, process: nil, recipient: ref)
      end
    else
      error -> {:error, {:invalid_ref, error}}
    end
  end
  
  defmacro __using__(_) do
    quote do
      require Noizu.AdvancedPool.Server
      require Noizu.AdvancedPool.WorkerSupervisor
      require Noizu.AdvancedPool.Message
      alias Noizu.AdvancedPool.Message, as: M
      import M
      require Noizu.AdvancedPool.NodeManager
      require Logger
      @pool __MODULE__
      @pool_supervisor Module.concat([__MODULE__, PoolSupervisor])
      @pool_worker_supervisor Module.concat([__MODULE__, WorkerSupervisor])
      @pool_server Module.concat([__MODULE__, Server])
      @pool_worker Module.concat([__MODULE__, Worker])
      @pool_registry Module.concat([__MODULE__, Registry])
      @pool_task_supervisor Module.concat([__MODULE__, Task])

      #-------------------------------------------
      # Pool reference and configuration
      # ========
      # These methods provide access to modules representing different components of the pool, as well as general configuration settings.
      #-------------------------------------------

      @doc """
      [INTERNAL]
      `__pool__/0` retrieves the Elixir module that represents the current pool.
      This function is typically used within the pool's own module to self-reference as part of configuration or operation management.

      tags: overridable, internal
      """
      @internal true
      def __pool__(), do: @pool

      @doc """
      [INTERNAL]
      `__pool_supervisor__/0` provides access to the supervisor module that oversees the entire pool.
      The supervisor module is integral to the supervision strategy and fault tolerance of the pool's process hierarchy.

      tags: overridable, internal
      """
      @internal true
      def __pool_supervisor__(), do: @pool_supervisor

      @doc """
      [INTERNAL]
      `__worker_supervisor__/0` returns the module that acts as the supervisor for worker processes within the pool.
      This function is central to the orchestration and management of the workers' lifecycle, including their supervision and scaling.

      tags: overridable, internal
      """
      @internal true
      def __worker_supervisor__(), do: Noizu.AdvancedPool.WorkerSupervisor

      @doc """
      [INTERNAL]
      `__worker_server__/0` retrieves the module representing the server responsible for interfacing with worker processes.
      It facilitates communication and coordination actions between the pool and individual workers.

      tags: overridable, internal
      """
      @internal true
      def __worker_server__(), do: Noizu.AdvancedPool.Worker.Server

      @doc """
      [INTERNAL]
      `__server__/0` accesses the server module within the pool, which handles request forwarding and load distribution among worker processes.
      This function forms part of the abstraction layer between the client's requests and the pool's workers.

      tags: overridable, internal
      """
      @internal true
      def __server__(), do: @pool_server

      @doc """
      [INTERNAL]
      `__worker__/0` gets the worker module that defines the behavior and functionalities of the workers within the pool.
      Workers are the fundamental units of work and this function provides a standard reference to their implemented module.

      tags: overridable, internal
      """
      @internal true
      def __worker__(), do: @pool_worker

      @doc """
      [INTERNAL]
      `__registry__/0` provides the registry module for the pool, which maintains the tracking and discovery of processes within the pool.
      It is crucial for the dynamic management of processes and efficient routing of messages.

      tags: overridable, internal
      """
      @internal true
      def __registry__(), do: @pool_registry

      @doc """
      [INTERNAL]
      `__task_supervisor__/0` returns the module used for task supervision within the pool.
      This supervisor is designed to manage background tasks and ensure robust asynchronous execution within the pool's architecture.

      tags: overridable, internal
      """
      @internal true
      def __task_supervisor__(), do: @pool_task_supervisor

      @doc """
      [INTERNAL]
      `__dispatcher__/0` returns the module responsible for routing and dispatching messages within the pool context,
      namely the `Noizu.AdvancedPool.DispatcherRouter`. It ensures that messages sent to workers are properly directed
      to the correct process, handling dynamic routing, load balancing, and worker process lifecycle events.

      tags: overridable, internal
      """
      @internal true
      def __dispatcher__(), do: Noizu.AdvancedPool.DispatcherRouter

      #-------------------------------------------
      #
      # ========
      #
      #-------------------------------------------
      @doc """
      [INTERNAL]
      `config/0` yields the configuration for the pool, supplying parameters and operational settings.
      This function should be overridden with custom logic to return specific configuration details for the pool,
      such as pooling strategies, timeouts, or other key-value settings. It's essential for customizing the pool's
      behavior and capabilities, tailoring the pool to the needs of a particular environment or application.

      tags: overridable, internal
      """
      def config() do
        with {:ok, config} <- Noizu.AdvancedPool.ClusterManager.config() do
          config[__pool__()] || []
        end
      end

      @doc """
      [INTERNAL]
      `__cast_settings__/0` provides default configuration settings for asynchronous cast operations within the pool.
      These settings dictate how cast messages are handled, including their timeout constraints.

      tags: overridable, internal
      """
      @internal true
      def __cast_settings__(), do: Noizu.AdvancedPool.Message.settings(timeout: 5000)

      @doc """
      [INTERNAL]
      `__call_settings__/0` specifies default settings for synchronous call operations within the pool.
      This function determines the handling of calls, particularly the behavior regarding the expected response time and timeouts.

      tags: overridable, internal
      """
      @internal true
      def __call_settings__(), do: Noizu.AdvancedPool.Message.settings(timeout: 60_000)

      @doc """
      `pool_scopes/0` compiles key identifiers for the various components that are instrumental within the pool's ecosystem.
      By invoking callbacks on the pool module, it retrieves references to the pool, server, worker supervisor, worker, and registry modules.
      The existence of this method streamlines complex interactions within the pool by providing an organized catalog of components,
      which in turn simplifies component management and supports debugging and maintenance tasks.

      tags: overridable
      """
      def pool_scopes() do
        Noizu.AdvancedPool.pool_scopes(__pool__())
      end

      #-------------------------------------------
      # Cluster integration and supervision tree management
      # ========
      # These methods are involved in managing the pool as part of a cluster and handling its supervision structure.
      #-------------------------------------------

      @doc """
      `join_cluster/3` integrates the pool into a distributed computing cluster to share resources and balance the workload.
      It achieves this by registering the supervisory process of the pool with the central NodeManager, using the pool's
      identifier, the process identifier (PID) of the supervisor process, the operational context, and additional configuration options.
      The provision of this method promotes scalable architecture as it allows the pool to extend its capabilities across nodes,
      ensuring efficient resource utilization and improved redundancy within a multi-node Elixir system.

      tags: overridable
      """
      def join_cluster(pid, context, options) do
        Noizu.AdvancedPool.join_cluster(__pool__(), pid, context, options)
      end

      @doc """
      `spec/1-2` constructs the definition (specification) for supervisory processes which are required to start the pool's main supervisory process.
      It formulates the start-up parameters using the pool's context and any additional options. The spec details include the module, function, and arguments required for launching the process.
      This method provides a standardized approach to defining the initiation parameters for the pool's supervisor, ensuring a consistent start-up procedure and facilitating the declaration of the pool's supervision strategy, which is fundamental for initializing and maintaining the pool's structure.

      tags: overridable
      """
      def spec(context, options \\ nil) do
        Noizu.AdvancedPool.DefaultSupervisor.spec(__MODULE__, context, options)
      end

      @doc """
      `add_worker_supervisor/2` facilitates the dynamic scaling of the pool by adding new worker supervisor processes to the supervision tree.
      This method uses the NodeManager to select an appropriate node and then provisions a new worker supervisor according to the provided specification.
      Adding worker supervisors dynamically is essential for handling increased demand or recovering from failures. It helps maintain the resilience and robustness of the pool by ensuring that workers are adequately supervised and that there is enough supervisory capacity to manage the pool's workers.

      tags: overridable
      """
      def add_worker_supervisor(node, spec) do
        Noizu.AdvancedPool.DefaultSupervisor.add_worker_supervisor(__MODULE__, node, spec)
      end

      @doc """
      `bring_online/1` transitions the pool's state from initialization to an active status within a cluster, marking it as ready to process work.
      It calls internal mechanisms to update the pool's registration with the NodeManager and joins the cluster manager service.
      This registration includes updating the status to online and setting the health metric indicating full operational capacity.
      The ability to bring a pool online is critical for a controlled startup sequence and for integrating the pool into the existing
      cluster, thus enabling it to commence handling workloads as part of the distributed system.

      tags: overridable
      """
      def bring_online(context) do
        pool = __pool__()
        with {pid, status} <- :syn.lookup(Noizu.AdvancedPool.NodeManager, {node(), pool}) do
          IO.puts "BRING ONLINE #{pool}"
          updated_status = pool_status(status, status: :online, health: 1.0)
          Noizu.AdvancedPool.NodeManager.set_service_status(pid, pool, node(), updated_status)
        end
      end


      @doc """
      `get_direct_link!/3-4` establishes a direct communication channel to a specific worker within the pool by
      returning a reference link that includes the worker's node and process identifier (PID).
      It takes a unique reference for the worker, the context of the call, and a set of options that can modify the
      behavior of the link retrieval. Behind the scenes, this method validates the worker's reference and retrieves its
      process details from the dispatcher router. If the reference validation or lookup fails, an error is raised.
      The method exists to provide an optimized path for message delivery by bypassing the standard messaging queue and
      enabling more immediate and direct interaction, which is particularly useful for time-sensitive or priority
      communications within the pool.
      """
      def get_direct_link!(ref, context, options \\ nil) do
        with {:ok, ref} <- apply(__worker__(), :ref_ok, [ref]) do
          Noizu.AdvancedPool.get_direct_link!(__pool__(), ref, context, options)
        end
      end

      #-------------------------------------------
      # Message Handling/Forwarding
      # ========
      #
      #-------------------------------------------

      @doc """
      `handle_call/3` provides a default implementation for handling incoming synchronous calls in a GenServer-like
      interface within the pool's context. It takes a message, the sender's information, and the current state as arguments.
      If the message is not caught by any specific clause, this function will respond with a tuple indicating the message
      is unhandled, preserving the original message and state in the response.

      This function exists as a placeholder, to be overridden with custom handling logic, ensuring that uncaught
      messages do not cause errors and are instead flagged for further investigation.
      """
      def handle_call(msg, _from, state) do
        {:reply, {:uncaught, msg, state}, state}
      end

      @doc """
      `handle_cast/2` offers a default behavior for processing incoming asynchronous cast messages. It accepts a message
      and the current state and, in the absence of a specific matching clause, returns `:noreply`, indicating the cast
      message is unhandled but silently acknowledging it, leaving the state unchanged.

      Similar to `handle_call/3`, this method is to be overridden with customized behavior designed for the specific use
      cases of the pool. It ensures a safe default operation where unhandled cast messages don't disrupt the process's flow.
      """
      def handle_cast(msg, state) do
        {:noreply, state}
      end

      @doc """
      `handle_info/2` handles generic informational messages received by the process. Upon receipt of an unexpected
      message that does not match any predefined patterns, it chooses to continue without sending a reply, returning
      `:noreply`, and maintaining the process's state.

      This method ensures robustness by allowing the process to safely ignore irrelevant or unplanned messages,
      thus keeping the process in a consistent state and ready for valid, anticipated interactions.
      """
      def handle_info(msg, state) do
        {:noreply, state}
      end

      @doc """
      `s_call!/2-4` complements the standard `s_call/2-4` by enforcing that if a worker referenced by `identifier`
      does not exist, it will be spawned before the message is delivered. This function is a wrapper
      around `Noizu.AdvancedPool.Message.Dispatch.s_call!`, which uses the provided `identifier`, `message`, `context`,
      and `options` to perform a synchronous call, ensuring that the message is sent to an existing or
      newly spawned worker process.

      This method is critical for scenarios where the existence of the target worker is necessary for the operation,
      such as time-critical or high-priority tasks, and the calling process requires certainty of message delivery.
      """
      def s_call!(identifier, message, context, options \\ nil) do
        with {:ok, ref} <- apply(__worker__(), :recipient, [identifier]) do
          Noizu.AdvancedPool.Message.Dispatch.s_call!(ref, message, context, options)
        end
      end

      @doc """
      `s_call/2-4` is used for sending a synchronous call to a worker within the pool, expecting a response.
      It acts as a thin wrapper around `Noizu.AdvancedPool.Message.Dispatch.s_call`, translating the
      provided `identifier`, `message`, `context`, and `options` into a message dispatch operation.
      This function assumes that the worker is already running and does not spawn new worker processes.

      The method facilitates synchronous communication when it's acceptable for the calling process to wait for the response,
      and it is used in cases where the worker is expected to be present, such as well-established workflows or steady-state operations.
      """
      def s_call(identifier, message, context, options \\ nil) do
        with {:ok, ref} <- apply(__worker__(), :recipient, [identifier]) do
          Noizu.AdvancedPool.Message.Dispatch.s_call!(ref, message, context, options)
        end
      end

      @doc """
      `s_cast!/2-4` behaves similarly to `s_cast/2-4`, with the additional guarantee that if the worker is not
      already running, it will be spawned. This function is based on `Noizu.AdvancedPool.Message.Dispatch.s_cast!`,
      using the same parameters—`identifier`, `message`, `context`, and `options`—to perform an asynchronous cast.
      If necessary, it ensures that the worker process is active and ready to receive the message.

      This method ensures that non-blocking communication can proceed even if the worker process needs to be created
      on the fly, which is vital when the workload is dynamic, and workers may not be continuously running.
      """
      def s_cast!(identifier, message, context, options \\ nil) do
        with {:ok, ref} <- apply(__worker__(), :recipient, [identifier]) do
          Noizu.AdvancedPool.Message.Dispatch.s_cast!(ref, message, context, options)
        end
      end

      @doc """
      `s_cast/2-4` sends an asynchronous cast message to a worker within the pool without expecting a response.
      It wraps the `Noizu.AdvancedPool.Message.Dispatch.s_cast` function, relaying the
      `identifier`, `message`, `context`, and `options` to initiate the cast operation.
      This variant will not spawn a worker process if the identified worker is not running.

      Utilized for fire-and-forget scenarios where the completion of the message handling does not need to be awaited
      or confirmed, this method is suited for workflows where workers are persistently running or
      when occasional message loss is acceptable.
      """
      def s_cast(identifier, message, context, options \\ nil) do
        with {:ok, ref} <- apply(__worker__(), :recipient, [identifier]) do
          Noizu.AdvancedPool.Message.Dispatch.s_cast(ref, message, context, options)
        end
      end

      #-------------------------------------------
      # Service Worker Hooks
      # ========
      #
      #-------------------------------------------

      @doc """
      `reload!/3` instructs a worker referenced by `ref` to reload its configuration or state.
      The function achieves this by making a synchronous call to the worker, ensuring the operation is executed before proceeding. The `context`
      and `options` parameters allow for passing additional information and control the behavior of the reload operation.
      This method is essential when the worker's runtime configuration needs to be updated dynamically without restarting the worker or the system.
      """
      def reload!(ref, context, options), do: s_call!(ref, :reload!, context, options)

      @doc """
      `fetch/3` retrieves specific information, denoted by `type`, from the worker identified by `ref`.
      It functions by performing a synchronous call and expects a response containing the requested data. The `context` parameter provides the
      contextual information necessary for the fetch operation.
      The fetch function is crucial for monitoring or management purposes, enabling retrieval of worker state or other relevant metrics.
      """
      def fetch(ref, type, context), do: s_call!(ref, {:fetch, type}, context)

      @doc """
      `ping/2` sends a synchronous 'ping' message to the worker identified by `ref`, checking its responsiveness.
      A response confirms that the worker is operational. The default implementation takes only the reference and the calling context as arguments.
      This function is commonly used to perform health checks or validate the presence and responsiveness of a worker.
      """
      def ping(ref, context), do: s_call(ref, :ping, context)

      @doc """
      `ping/3` is an overloaded variant of `ping/2`, providing an additional `options` parameter to control the ping operation's behavior.
      This variant allows for a more customized health check or responsiveness verification, offering tailored interaction with the worker process.
      """
      def ping(ref, context, options), do: s_call(ref, :ping, context, options)


      @doc """
      `kill!/3` forcefully terminates the worker identified by `ref`.
      The function ensures that the terminate command is executed synchronously through a call operation, taking into account the calling `context`
      and any special `options` that may influence the termination process.
      This method serves as an immediate way to control the lifecycle of workers, particularly in emergency situations or when decommissioning
      specific processes is necessitated.
      """
      def kill!(ref, context, options), do: s_call(ref, :kill!, context, options)


      @doc """
      `crash!/3` purposefully causes the worker identified by `ref` to crash.
      This method, which uses a synchronous call, is intended for testing the robustness of the pool's error recovery mechanisms. It accepts a calling
      `context` and optional `options` that may govern how the crash is executed.
      Crash testing is a vital part of chaos engineering practices, verifying that the system can withstand unexpected failures gracefully.
      """
      def crash!(ref, context, options), do: s_call(ref, :crash!, context, options)


      @doc """
      `hibernate/3` puts the worker specified by `ref` into a hibernation state.
      A synchronous call ensures the hibernation command is successfully received and acted upon. The `context` and `options` provide the necessary
      details for the hibernation action. This method helps conserve system resources during periods of worker inactivity.
      """
      def hibernate(ref, context, options), do: s_call!(ref, :hibernate, context, options)

      @doc """
      `persist!/3` triggers a save operation that persists the current state of the worker identified by `ref`.
      Making this operation a synchronous call ensures that state persistence is completed before proceeding. `Context` and `options` parameters
      are used to adapt the save operation to specific requirements.
      Persisting state is crucial for fault-tolerant systems where worker state needs to be maintained across restarts or failures.
      """
      def persist!(ref, context, options), do: s_call!(ref, :persist!, context, options)

      defoverridable [
        __pool__: 0,
        __pool_supervisor__: 0,
        __worker_supervisor__: 0,
        __worker_server__: 0,
        __server__: 0,
        __worker__: 0,
        __registry__: 0,
        __task_supervisor__: 0,
        __dispatcher__: 0,
        __cast_settings__: 0,
        __call_settings__: 0,
        join_cluster: 3,
        pool_scopes: 0,
        config: 0,
        spec: 1,
        spec: 2,
        get_direct_link!: 2,
        get_direct_link!: 3,
        bring_online: 1,
        add_worker_supervisor: 2,
        handle_call: 3,
        handle_cast: 2,
        handle_info: 2,
  
        reload!: 3,
        fetch: 3,
        ping: 3,
        ping: 2,
        kill!: 3,
        crash!: 3,
        hibernate: 3,
        persist!: 3,
      ]
      
    end
  end
end
