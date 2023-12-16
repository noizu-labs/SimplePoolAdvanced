defmodule Noizu.AdvancedPool.DispatcherRouter do
  @moduledoc """
  Provides routing and dispatching services for worker processes within the Noizu AdvancedPool framework.

  This module is responsible for locating and registering worker processes, dispatching messages to workers,
  and initiating workers when necessary. It offers a set of core functions used by the AdvancedPool system to
  manage worker processes in a distributed environment efficiently.

  Functionality includes:

  - Finding worker processes in the pool's registry.
  - Registering worker processes with their associated metadata.
  - Handling message dispatching, which may involve starting new workers if they are not currently running and are needed.
  - Providing internal support for dynamic dispatch within the pool's context.

  Internally, the module leverages the `:syn` library to perform operations on a registry that keeps track of active
  worker processes. It uses Elixir's `apply/3` mechanism to dynamically call functions related to pool operations,
  increasing the flexibility and scalability of the worker management system.

  While the core functionalities are designed to be system-internal, they play a critical role in enabling AdvancedPool
  to maintain a responsive and resilient pool of workers, capable of handling incoming requests and performing distributed
  tasks across multiple nodes in a cluster.
  """

  require Logger
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M

  @doc """
  [INTERNAL]
  Initiates the process of starting a worker within the specified pool using the provided reference and settings.

  It enriches the provided options with a `:return_task` flag set to `true`, ensuring that the `start_worker` function of the `ClusterManager` will return a task. The function then delegates to the `ClusterManager.start_worker/5` to begin the worker start-up sequence.

  This function is essential for spinning up new worker processes in the pool in response to system demands, providing dynamic scalability and responsiveness to load.
  """
  @internal true
  def start_worker(pool, ref, settings, context, options) do
    options_b = put_in(options || [], [:return_task], true)
    Noizu.AdvancedPool.ClusterManager.start_worker(pool, ref, settings, context,  options_b)
  end

  @doc """
  [INTERNAL]
  Looks up a worker process in the registry using its reference.

  Utilizes the `:syn` library to query the registry for the provided worker reference. Returns a tuple with the worker's PID and additional informational metadata if found, or an error tuple if the worker is not registered.

  This function is part of the internal mechanics that allow rapid resolution of process identifiers, a fundamental aspect of efficient message dispatch within a distributed system.
  """
  @internal true
  def __lookup_worker_process__(ref = M.ref(module: worker, identifier: identifier)) do
    registry = apply(worker, :__registry__, [])
    with {pid, info} <- :syn.lookup(registry, {:worker, ref}) do
      {:ok, {pid, info}}
    else
      _ -> {:error, :unregistered}
    end
  end

  @doc """
  [INTERNAL]
  Processes messages intended for workers, handling registration and dispatching logic.

  First, it attempts to resolve the recipient process' PID via the registry. If unresolved and auto-spawning is enabled, it delegates to `start_worker/5` to create the worker. It encapsulates internal decision-making for how messages should be routed based on the recipient's current state or needs.

  This "__process__" function forms a critical part of the message routing lifecycle, ensuring messages reach their intended destinations or are handled appropriately if they do not.
  """
  @internal true
  def __process__(message, _ \\ nil)
  def __process__(
        M.msg_envelope(
          recipient: ref = M.ref(module: worker, identifier: identifier),
          msg: msg,
          settings: settings
        ) = message,
        options
      ) do
    
    # we will need to tweak this eventually to better scale.
    # only register/ref scopes on nodes with the services (or a subset of that) and rpc.call to the node of an
    # available node manager to get the actual pid rather than syncing values across entire cluster, etc.
    
    # regardless for large scales we will likely need to tweak our registration flow here.
    registry = apply(worker, :__registry__, [])
    with {pid, _} <- :syn.lookup(registry, {:worker, ref})
                     #|> IO.inspect(label: "#{registry} check #{inspect ref}")
      do
      {:ok, pid}
    else
      :undefined ->
        cond do
          spawn?(settings) ->
            {:dispatch, __MODULE__, :waiting, start_worker(apply(worker, :__pool__, []), ref, settings, M.call_context(msg), options)}
          :else -> {:nack, :not_registered}
        end
    end
  catch e -> {:error, e}
  end


  @doc """
  [INTERNAL]
  Provides a routing handle for dynamic dispatch to this module.

  Always returns a routing tuple indicating that the dispatcher is this module itself, along with an empty list, representing the default routing state.

  Used internally by the system to resolve where to direct dynamic dispatch operations, acting as a bootstrap point for message routing resolution.
  """
  @internal true
  def __handle__(_, _), do: {:dynamic, __MODULE__, [[]]}


  @doc """
  [INTERNAL]
  Registers a worker process in the pool's registry, marking it with the provided status.

  Utilizes `:syn.register` to associate the worker's reference with its process identifier and status, updating the registry to reflect its current state.

  This method is integral to the system's ability to manage and track the multitude of worker processes, ensuring accurate and up-to-date process information within the pool's registry.
  """
  @internal true
  def __register__(pool, ref, process, status) do
    registry = apply(pool, :__registry__, [])
    :syn.register(registry, {:worker, ref}, process, status)
    # @TODO increment node's worker count ets table - initializations
    # on terminate increment node's worker ets table - terminations
  end

end
