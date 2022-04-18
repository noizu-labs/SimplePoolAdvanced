#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.AdvancedPool.MessageProcessingBehaviour.Default do
  require Logger

  @type bare_call :: {type :: :s | :i |:m , call :: any, context :: Noizu.ElixirCore.CallingContext.t}
  @type bare_with_startup :: {spawn? :: :spawn | :passive, call :: bare_call}
  @type call_type :: :s_cast | :s_cast! | :s_call | :s_call! | :i_call | :_cast
  @type redirect_call :: {:msg_redirect, {server :: module, {call_type, ref :: tuple, timeout :: integer | :infinity}}, bare_with_startup}
  @type call_envelope :: {:msg_envelope, {server :: module, {call_type, ref :: tuple, timeout :: integer | :infinity}}, bare_with_startup}


  #-----------------------------------------------------
  # handle_call
  #-----------------------------------------------------
  @doc """
  Message Redirect Support (V2) not compatible with V1
  """

  # Service matches redirect to Service
  def __handle_call__(module, {:msg_redirect, {module, _delivery_details}, call = {_spawn, {_msg_type, _call, _context}}}, from, state), do: __handle_call__(module, call, from, state)

  # Service does not not match redirect Service.
  def __handle_call__(module, {:msg_redirect, {call_server, {_call_type, ref, _timeout}}, call = {_spawn, {_msg_type, _call, context}}} = fc, _from, state) do
    Logger.warn fn -> {"Redirecting Call #{inspect call_server}-#{inspect call, pretty: true}\n\n", Noizu.ElixirCore.CallingContext.metadata(context)} end
    try do
      Logger.error fn -> {"Redirect Failed! #{inspect call_server}-#{inspect fc, pretty: true}", Noizu.ElixirCore.CallingContext.metadata(context)} end
      # Clear lookup entry to allow system to assign correct entry and spawn new entry.
      call_server.worker_management().unregister!(ref, context, %{})
    rescue e -> Logger.error "[MessageProcessing] - Exception Raised #{inspect e}", Noizu.ElixirCore.CallingContext.metadata(context)
    catch e -> Logger.error "[MessageProcessing] - Exception Thrown #{inspect e}", Noizu.ElixirCore.CallingContext.metadata(context)
    end
    {:reply, {:s_retry, call_server, module}, state}
  end

  # Matching Message Envelope Service
  def __handle_call__(module, {:msg_envelope, {module, _delivery_details}, call = {_spawn, {_msg_type, _call, _context}}}, from, state), do: __handle_call__(module, call, from, state)

  # Mismatched Service
  def __handle_call__(module, {:msg_envelope, {call_server, {_call_type, ref, _timeout}}, call = {_spawn, {_msg_type, _call, context}}}, _from, state) do
    Logger.warn fn -> {"Redirecting Call #{inspect call_server}-#{inspect call, pretty: true}\n\n", Noizu.ElixirCore.CallingContext.metadata(context)} end
    try do
      Logger.warn fn -> {"Redirecting Call #{inspect call_server}-#{inspect call, pretty: true}\n\n", Noizu.ElixirCore.CallingContext.metadata(context)} end
      # Clear lookup entry to allow system to assign correct entry and spawn new entry.
      call_server.worker_management().unregister!(ref, context, %{})
    rescue e -> Logger.error "[MessageProcessing] - Exception Raised #{inspect e}", Noizu.ElixirCore.CallingContext.metadata(context)
    catch e -> Logger.error "[MessageProcessing] - Exception Thrown #{inspect e}", Noizu.ElixirCore.CallingContext.metadata(context)
    end
    {:reply, {:s_retry, call_server, module}, state}
  end

  # Forward on to our call handler.
  def __handle_call__(module, envelope, from, state), do: module.__handle_call__(envelope, from, state)

  #-----------------------------------------------------
  # handle_cast
  #-----------------------------------------------------
  # Service matches redirect to Service
  def __handle_cast__(module, {:msg_redirect, {module, _delivery_details}, call = {_spawn, {_msg_type, _call, _context}}}, state), do: __handle_cast__(module, call, state)

  # Service does not not match redirect Service.
  def __handle_cast__(_module, {:msg_redirect, {call_server, {call_type, ref, _timeout}}, call = {_spawn, {_msg_type, payload, context}}} = _fc, state) do
    spawn fn ->
      try do
        Logger.warn fn -> {"Redirect Failed #{inspect call_server}-#{inspect call, pretty: true}\n\n", Noizu.ElixirCore.CallingContext.metadata(context)} end
        # Clear lookup entry to allow system to assign correct entry and spawn new entry.
        call_server.worker_management().unregister!(ref, context, %{})
        apply(call_server.router(), call_type, [ref, payload, context]) # todo, deal with call options.
      rescue e -> Logger.error "[MessageProcessing] - Exception Raised #{inspect e}", Noizu.ElixirCore.CallingContext.metadata(context)
      catch e -> Logger.error "[MessageProcessing] - Exception Thrown #{inspect e}", Noizu.ElixirCore.CallingContext.metadata(context)
      end
    end
    {:noreply, state}
  end

  # Matching Message Envelope Service
  def __handle_cast__(module, {:msg_envelope, {module, _delivery_details}, call = {_spawn, {_msg_type, _call, _context}}}, state), do: __handle_cast__(module, call, state)

  # Mismatched Service
  def __handle_cast__(_module, {:msg_envelope, {call_server, {call_type, ref, _timeout}}, call = {_spawn, {_msg_type, payload, context}}}, state) do
    spawn fn ->
      try do
        Logger.warn fn -> {"Redirecting Cast #{inspect call_server}-#{inspect call, pretty: true}\n\n", Noizu.ElixirCore.CallingContext.metadata(context)} end
        # Clear lookup entry to allow system to assign correct entry and spawn new entry.
        call_server.worker_management().unregister!(ref, context, %{})
        apply(call_server.router(), call_type, [ref, payload, context]) # todo, deal with call options.
      rescue e -> Logger.error "[MessageProcessing] - Exception Raised #{inspect e}", Noizu.ElixirCore.CallingContext.metadata(context)
      catch e -> Logger.error "[MessageProcessing] - Exception Thrown #{inspect e}", Noizu.ElixirCore.CallingContext.metadata(context)
      end
    end
    {:noreply, state}
  end

  # Forward on to our call handler.
  def __handle_cast__(module, envelope, state), do: module.__handle_cast__(envelope, state)

  #-----------------------------------------------------
  # handle_info
  #-----------------------------------------------------
  def __handle_info__(module, {:msg_redirect, {module, _delivery_details}, call = {_spawn, {_msg_type, _call, _context}}}, state), do: __handle_info__(module, call, state)
  def __handle_info__(_module, {:msg_redirect, {call_server, {call_type, ref, _timeout}}, call = {_spawn, {_msg_type, payload, context}}} = _fc, state) do
    spawn fn ->
      try do
        Logger.warn fn -> {"Redirect Failed #{inspect call_server}-#{inspect call, pretty: true}\n\n", Noizu.ElixirCore.CallingContext.metadata(context)} end
        # Clear lookup entry to allow system to assign correct entry and spawn new entry.
        call_server.worker_management().unregister!(ref, context, %{})
        apply(call_server.router(), call_type, [ref, payload, context]) # todo, deal with call options.
      rescue e -> Logger.error "[MessageProcessing] - Exception Raised #{inspect e}"
      catch e -> Logger.error "[MessageProcessing] - Exception Thrown #{inspect e}"
      end
    end
    {:noreply, state}
  end

  def __handle_info__(module, {:msg_envelope, {module, _delivery_details}, call = {_spawn, {_msg_type, _call, _context}}}, state), do: __handle_info__(module, call, state)
  def __handle_info__(_module, {:msg_envelope, {call_server, {call_type, ref, _timeout}}, call = {_spawn, {_msg_type, payload, context}}}, state) do
    spawn fn ->
      try do
        Logger.warn fn -> {"Redirecting Cast #{inspect call_server}-#{inspect call, pretty: true}\n\n", Noizu.ElixirCore.CallingContext.metadata(context)} end
        # Clear lookup entry to allow system to assign correct entry and spawn new entry.
        call_server.worker_management().unregister!(ref, context, %{})
        apply(call_server.router(), call_type, [ref, payload, context]) # todo, deal with call options.
      rescue e -> Logger.error "[MessageProcessing] - Exception Raised #{inspect e}"
      catch e -> Logger.error "[MessageProcessing] - Exception Thrown #{inspect e}"
      end
    end
    {:noreply, state}
  end

  @doc """
  Catchall
  """
  def __handle_info__(module, envelope, state), do: module.__handle_info__(envelope, state)

  #===============================================================================================================
  # Default delegation
  #===============================================================================================================
  def __call_router_catchall__(module, envelope, _from, state) do
    Logger.error("#{module}.call_catchall - uncaught #{inspect envelope}")
    {:reply, :error, state}
  end
  def __cast_router_catchall__(module, envelope, state) do
    Logger.error("#{module}.cast_catchall - uncaught #{inspect envelope}")
    {:noreply, state}
  end
  def __info_router_catchall__(module, envelope, state) do
    Logger.error("#{module}.info_catchall - uncaught #{inspect envelope}")
    {:noreply, state}
  end


  #----------------------------------------------
  # __delegate_handle_call__/4 - pass message from worker/standalone server module to inner_state handler.
  #----------------------------------------------
  def __delegate_handle_call__(m, _envelope = {:spawn, call = {_msg_type, _call, context}}, from, %Noizu.AdvancedPool.Worker.State{initialized: :delayed_init} = state) do
    m.__delegate_handle_call__({:passive, call}, from, m.delayed_init(state, context))
  end

  def __delegate_handle_call__(m, _envelope = {:spawn, call = {_, _call, context}}, from, %Noizu.AdvancedPool.Worker.State{initialized: false} = state) do
    case m.pool_worker_state_entity().load(state.worker_ref, context, %{}) do
      nil -> {:reply, :error, state}
      inner_state -> m.__delegate_handle_call__(m, {:passive, call}, from, %Noizu.AdvancedPool.Worker.State{state| initialized: true, inner_state: inner_state})
    end
  end

  def __delegate_handle_call__(m, call, from, state = %{inner_state: %{__struct__: inner_module}}) do
    if m.__meta__()[:inactivity_check] do
      l = :os.system_time(:seconds)
      case inner_module.__handle_call__(call, from, state.inner_state) do
        {:reply, response, inner_state} -> {:reply, response, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:reply, response, inner_state, hibernate} -> {:reply, response, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
        {:stop, reason, inner_state} -> {:stop, reason, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:stop, reason, response, inner_state} -> {:stop, reason, response, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:noreply, inner_state} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
      end
    else
      case inner_module.__handle_call__(call, from, state.inner_state) do
        {:reply, response, inner_state} -> {:reply, response, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:reply, response, inner_state, hibernate} -> {:reply, response, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}, hibernate}
        {:stop, reason, inner_state} -> {:stop, reason, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:stop, reason, response, inner_state} -> {:stop, reason, response, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:noreply, inner_state} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}, hibernate}
      end
    end
  end

  def __delegate_handle_call__(_m, call, _from, state) do
    {:reply, {:uncaught, call}, state}
  end


  #----------------------------------------------
  # __delegate_handle_cast__/3 - pass message from worker/standalone server module to inner_state handler.
  #----------------------------------------------
  def __delegate_handle_cast__(m, _envelope = {:spawn, call = {_msg_type, _call, context}}, %Noizu.AdvancedPool.Worker.State{initialized: :delayed_init} = state) do
    m.__delegate_handle_cast__({:passive, call}, m.delayed_init(state, context))
  end

  def __delegate_handle_cast__(m, _envelope = {:spawn, call = {_, _call, context}}, %Noizu.AdvancedPool.Worker.State{initialized: false} = state) do
    case m.pool_worker_state_entity().load(state.worker_ref, context, %{}) do
      nil -> {:reply, :error, state}
      inner_state -> m.__delegate_handle_cast__(m, {:passive, call}, %Noizu.AdvancedPool.Worker.State{state| initialized: true, inner_state: inner_state})
    end
  end

  def __delegate_handle_cast__(m, call, state = %{inner_state: %{__struct__: inner_module}}) do
    if m.__meta__()[:inactivity_check] do
      l = :os.system_time(:seconds)
      case inner_module.__handle_cast__(call, state.inner_state) do
        {:reply, _response, inner_state} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:reply, _response, inner_state, hibernate} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
        {:stop, reason, inner_state} -> {:stop, reason, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:stop, reason, _response, inner_state} -> {:stop, reason, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:noreply, inner_state} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
      end
    else
      case inner_module.__handle_cast__(call, state.inner_state) do
        {:reply, _response, inner_state} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:reply, _response, inner_state, hibernate} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}, hibernate}
        {:stop, reason, inner_state} -> {:stop, reason, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:stop, reason, _response, inner_state} -> {:stop, reason, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:noreply, inner_state} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}, hibernate}
      end
    end
  end

  def __delegate_handle_cast__(_m, _call, state) do
    {:noreply, state}
  end

  #----------------------------------------------
  # __delegate_handle_info__/3 - pass message from worker/standalone server module to inner_state handler.
  #----------------------------------------------
  def __delegate_handle_info__(m, _envelope = {:spawn, call = {_msg_type, _call, context}}, %Noizu.AdvancedPool.Worker.State{initialized: :delayed_init} = state) do
    m.__delegate_handle_info__({:passive, call}, m.delayed_init(state, context))
  end

  def __delegate_handle_info__(m, _envelope = {:spawn, call = {_, _call, context}}, %Noizu.AdvancedPool.Worker.State{initialized: false} = state) do
    case m.pool_worker_state_entity().load(state.worker_ref, context, %{}) do
      nil -> {:reply, :error, state}
      inner_state -> m.__delegate_handle_info__(m, {:passive, call}, %Noizu.AdvancedPool.Worker.State{state| initialized: true, inner_state: inner_state})
    end
  end

  def __delegate_handle_info__(m, call, state = %{inner_state: %{__struct__: inner_module}}) do
    if m.__meta__()[:inactivity_check] do
      l = :os.system_time(:seconds)
      case inner_module.__handle_info__(call, state.inner_state) do
        {:reply, _response, inner_state} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:reply, _response, inner_state, hibernate} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
        {:stop, reason, inner_state} -> {:stop, reason, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:stop, reason, _response, inner_state} -> {:stop, reason, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:noreply, inner_state} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}}
        {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
      end
    else
      case inner_module.__handle_cast__(call, state.inner_state) do
        {:reply, _response, inner_state} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:reply, _response, inner_state, hibernate} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}, hibernate}
        {:stop, reason, inner_state} -> {:stop, reason, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:stop, reason, _response, inner_state} -> {:stop, reason, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:noreply, inner_state} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}}
        {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.AdvancedPool.Worker.State{state| inner_state: inner_state}, hibernate}
      end
    end
  end

  def __delegate_handle_info__(_m, _call, state) do
    {:noreply, state}
  end



  #----------------------------------------------
  # as_cast
  #----------------------------------------------
  def as_cast(response) do
    case response do
      {:reply, _response, state} -> {:noreply, state}
      {:reply, _response, state, hibernate} -> {:noreply, state, hibernate}
      {:stop, reason, state} -> {:stop, reason, state}
      {:stop, reason, _response, state} -> {:stop, reason, state}
      {:noreply, state} -> {:noreply, state}
      {:noreply, state, hibernate} -> {:noreply, state, hibernate}
    end
  end

  def as_info(response), do: as_cast(response)

end
