defmodule Noizu.AdvancedPool.WorkerSupervisor do
  @moduledoc """
  Defines the worker supervisor module within the `Noizu.AdvancedPool` system. The `WorkerSupervisor` is a specialized
  DynamicSupervisor responsible for starting, stopping, and managing the pool's worker processes.

  Leveraging the robust, fault-tolerant design patterns of Elixir's OTP, this module is tasked with dynamically managing
  a subtree of workers within the pool. It registers itself with the pool's NodeManager, ensuring its presence and readiness
  to spawn new worker processes as needed.

  By adopting a `:one_for_one` supervision strategy, the `WorkerSupervisor` provides guarantees that if a worker crashes or
  terminates unexpectedly, a new one will be started to take its place, preserving the resilience of the system.
  """

  use DynamicSupervisor
 
  
  def start_link(pool, context, options) do
    DynamicSupervisor.start_link(__MODULE__, {pool, context, options})
    #|> IO.inspect(label: "#{pool}.worker.supervisor start_link")
  end


  @doc """
  Initializes the `WorkerSupervisor` with the given `pool`, `context`, and `options`. As part of its initialization,
  it registers itself with the `NodeManager`, which is instrumental in the coordination of workers across the cluster.
  The `:one_for_one` strategy is set, establishing the principle that only the crashed child process will be restarted,
  ensuring focused and contained fault recovery behavior.
  """
  def init({pool, context, options}) do
    Noizu.AdvancedPool.NodeManager.register_worker_supervisor(pool, self(), context, options)
    DynamicSupervisor.init(strategy: :one_for_one)
  end


  @doc """
  Generates a child specification for the supervisor, which includes an identifier, supervisor type, and the function
  along with its arguments necessary to start a new worker supervisor process within the pool.

  This `spec/4` function is crucial for the scalability of the system, providing a blueprint for creating new instances
  of worker supervisors under the dynamic supervisor, which in turn allows for the elastic management of the worker processes.
  """
  def spec(identifier, pool, context, options) do
    %{
      id: identifier,
      type: :supervisor,
      start: {__MODULE__, :start_link, [pool, context, options]}
    }
  end


  @doc """
  Starts an individual worker process using the provided `spec` under the given `sup` (DynamicSupervisor). This function
  facilitates the on-demand scaling of the worker pool, enabling the addition of worker processes to handle increased load
  or replace those that have terminated.

  The `add_worker/2` function is fundamental to the dynamic nature of the pool, where workers can be spawned and
  maintained in response to the actual working conditions and requirements encountered at runtime.
  """
  def add_worker(sup, spec) do
    DynamicSupervisor.start_child(sup, spec)
    #|> IO.inspect(label: "worker.supervisor start_child")
  end

end
