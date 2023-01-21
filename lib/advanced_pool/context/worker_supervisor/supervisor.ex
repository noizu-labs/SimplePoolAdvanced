defmodule Noizu.AdvancedPool.WorkerSupervisor do
  use DynamicSupervisor
  def start_link(pool, context, options) do
    DynamicSupervisor.start_link(__MODULE__, {pool, context, options})
  end

  def init_pool_status(pid, pool) do
    attributes = [node: node(), count: 0, last_update: :os.system_time(:second)]
    :syn.join(pool, {node(), :worker_supervisor}, pid, attributes)
    :syn.join(pool, :worker_supervisor, pid, attributes)
  end
  
  def refresh_pool_status(pid, pool) do
    with %{active: n} <- DynamicSupervisor.count_children(pid) do
      attributes = [node: node(), count: n, last_update: :os.system_time(:second)]
      :syn.join(pool, {node(), :worker_supervisor}, pid, attributes)
      :syn.join(pool, :worker_supervisor, pid, attributes)
    end
  end
  
  def init({pool, _context, _options}) do
    init_pool_status(self(), pool)
    DynamicSupervisor.init(strategy: :one_for_one)
  end
  
  def spec(identifier, pool, context, options) do
    %{
      id: identifier,
      type: :supervisor,
      start: {__MODULE__, :start_link, [pool, context, options]}
    }
  end
  
  
  
end