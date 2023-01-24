defmodule Noizu.AdvancedPool.Message.Handle do
  require Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M

  def recipient_check(M.msg_envelope(recipient: recipient), _from, %Noizu.AdvancedPool.Worker.State{} = worker) do
    with {:ok, ref} <- Noizu.AdvancedPool.Message.Dispatch.recipient_ref(recipient) do
        cond do
          ref == worker.identifier -> :ok
          :else -> {:error, :redirect}
        end
    else
      _ -> {:error, :invalid_or_legacy_recipient}
    end
  end
  
  def recipient_check(_call, _from, _state) do
    :ok
  end


  def recipient_check(M.msg_envelope(recipient: recipient), %Noizu.AdvancedPool.Worker.State{} = worker) do
    with {:ok, ref} <- Noizu.AdvancedPool.Message.Dispatch.recipient_ref(recipient) do
      cond do
        ref == worker.identifier -> :ok
        :else -> {:error, :redirect}
      end
    else
      _ -> {:error, :invalid_or_legacy_recipient}
    end
  end
  def recipient_check(_call, _state) do
    :ok
  end


  def worker_check(%Noizu.AdvancedPool.Worker.State{status: :loaded} = state) do
    {:ok, state}
  end
  def worker_check(%Noizu.AdvancedPool.Worker.State{status: :init} = state) do
    with {:ok, state} <- apply(state.handler, :load, [state, Noizu.ElixirCore.CallingContext.system()]) do
      {:ok, state}
    end
  end
  def worker_check(%Noizu.AdvancedPool.Worker.State{} = state) do
    {:error, {:invalid_state, state.status}}
  end
  def worker_check(state) do
    {:ok, state}
  end
  
  
  
  def reroute(_call, _from, state) do
    # inform caller.
    task = nil
    {:reply, {:nz_ap_forward, task}, state}
  end
  def reroute(_call, state) do
    #task = nil
    {:noreply, state}
  end

  def drop(_call, _from, state) do
    # inform caller.
    {:reply, {:error, :message_delivery_error}, state}
  end
  def drop(_call, state) do
    #task = nil
    {:noreply, state}
  end
  
  
  # pass in value to avoid inspecting state object.
  def handler(%{handler: h}), do: h
  def handler(%{__struct__: s}), do: s
  
  
  def unpack_call(M.msg_envelope(msg: m) = call, from, %{__struct__: _} = state) do
    with :ok <- recipient_check(call, from, state),
         {:ok, state} <- worker_check(state) do
      handler(state)
      |> apply(:handle_call, [m, from, state])
    else
      {:error, :redirect} -> reroute(call, from, state)
      error = {:error, {:invalid_state,state}} -> {:reply, error,  state}
      _ -> drop(call, from, state)
    end
  end
  
  def unpack_cast(M.msg_envelope(msg: m) = call, %{__struct__: _} = state) do
    with :ok <- recipient_check(call, state),
         {:ok, state} <- worker_check(state) do
      handler(state)
      |> apply(:handle_cast, [m, state])
    else
      {:error, :redirect} -> reroute(call, state)
      {:error, {:invalid_state,_}} -> {:noreply, state}
      _ -> drop(call, state)
    end
  end

  def unpack_info(M.msg_envelope(msg: m) = call, %{__struct__: _} = state) do
    with :ok <- recipient_check(call, state),
         {:ok, state} <- worker_check(state) do
      handler(state)
      |> apply(:handle_info, [m, state])
    else
      {:error, :redirect} -> reroute(call, state)
      {:error, {:invalid_state,_}} -> {:noreply, state}
      _ -> drop(call, state)
    end
  end
  
  def uncaught_call(msg, _, state) do
    {:reply, {:uncaught, msg, Noizu.ERP.ref(state)}, state}
  end
  def uncaught_cast(_, state) do
    {:noreply, state}
  end
  def uncaught_info(_, state) do
    {:noreply, state}
  end
  
end