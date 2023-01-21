defmodule Noizu.AdvancedPool.DispatcherRouter do
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M
  
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
    with {pid, _} <- :syn.lookup(registry, ref) do
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
  
  def start_worker(pool, ref, settings, context, options) do
    options_b = put_in(options || [], [:return_task], true)
    Noizu.AdvancedPool.ClusterManager.start_worker(pool, ref, settings, context,  options_b)
  end
  
  def __handle__(_, _), do: {:dynamic, __MODULE__, [[]]}
  
  def __register__(pool, ref, process, status) do
    registry = apply(pool, :__registry__, [])
    :syn.register(registry, ref, process, status)
  end

end