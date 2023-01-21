defmodule Noizu.AdvancedPool.DispatcherRouter do
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M
  
  def __process__(
        M.ref(module: worker, identifier: identifier) = ref,
        settings,
        options
      ) do

    # we will need to tweak this eventually to better scale.
    # only register/ref scopes on nodes with the services (or a subset of that) and rpc.call to the node of an
    # available node manager to get the actual pid rather than syncing values across entire cluster, etc.
    
    # regardless for large scales we will likely need to tweak our registration flow here.
    registry = apply(worker, :__registry__, [])
    with {pid, _} <- :syn.lookup(registry, ref) do
      {:ok, pid}
    end
    catch e -> {:error, e}
  end

  def __handle__(_, _), do: {:dynamic, __MODULE__, [[]]}
  
  def __register__(pool, ref, process, status) do
    registry = apply(pool, :__registry__, [])
    :syn.register(registry, ref, process, status)
  end
  
end