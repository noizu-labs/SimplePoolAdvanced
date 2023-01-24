defmodule Noizu.AdvancedPool.Message.Handle do
  require Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M

  def recipient_check(_call, _from, _state) do
    :ok
  end
  def recipient_check(_call, _state) do
    :ok
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
  
  # pass in value to avoid inspecting state object.
  def handler(%{handler: h}), do: h
  def handler(%{__struct__: s}), do: s
  
  
  def unpack_call(M.msg_envelope(msg: m) = call, from, %{__struct__: _} = state) do
    with :ok <- recipient_check(call, from, state) do
      handler(state)
      |> apply(:handle_call, [m, from, state])
    else
      _ -> reroute(call, from, state)
    end
  end
  
  def unpack_cast(M.msg_envelope(msg: m) = call, %{__struct__: _} = state) do
    with :ok <- recipient_check(call, state) do
      handler(state)
      |> apply(:handle_cast, [m, state])
    else
      _ -> reroute(call, state)
    end
  end

  def unpack_info(M.msg_envelope(msg: m) = call, %{__struct__: _} = state) do
    with :ok <- recipient_check(call, state) do
      handler(state)
      |> apply(:handle_info, [m, state])
    else
      _ -> {:noreply, state}
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