#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SimplePool.V2.MessageProcessingBehaviour do
  require Logger

  # call routing
  @callback call_router_user(any, any, any) :: any
  @callback call_router_internal(any, any, any) :: any
  @callback call_router_catchall(any, any, any) :: any
  @callback __call_handler(any, any, any) :: any

  # cast routing
  @callback cast_router_user(any, any) :: any
  @callback cast_router_internal(any, any) :: any
  @callback cast_router_catchall(any, any) :: any
  @callback __cast_handler(any, any) :: any

  # info routing
  @callback info_router_user(any, any) :: any
  @callback info_router_internal(any, any) :: any
  @callback info_router_catchall(any, any) :: any
  @callback __info_handler(any, any) :: any


  defmodule Default do
    #-----------------------------------------------------
    # handle_call
    #-----------------------------------------------------
    @doc """
    Message Redirect Support (V2) not compatible with V1
    """
    def __handle_call(module, {:msg_redirect, {module, _delivery_details}, call = {_s, _call, _context}}, from, state), do: __handle_call(module, call, from, state)
    def __handle_call(module, {:msg_redirect, {call_server, {_call_type, ref, _timeout}}, call = {_type, _payload, context}} = fc, _from, state) do
      Logger.warn fn -> "Redirecting Call #{inspect call_server}-#{inspect call, pretty: true}\n\n" end
      try do
        Logger.error fn -> {"Redirect Failed! #{inspect call_server}-#{inspect fc, pretty: true}", Noizu.ElixirCore.CallingContext.metadata(context)} end
        # Clear lookup entry to allow system to assign correct entry and spawn new entry.
        call_server.worker_management().unregister!(ref, context, %{})
      rescue e -> Logger.error "[MessageProcessing] - Exception Raised #{inspect e}"
      catch e -> Logger.error "[MessageProcessing] - Exception Thrown #{inspect e}"
      end
      {:reply, {:s_retry, call_server, module}, state}
    end

    def __handle_call(module, {:msg_envelope, {module, _delivery_details}, call = {_s, _call, _context}}, from, state), do: __handle_call(module, call, from, state)
    def __handle_call(module, {:msg_envelope, {call_server, {_call_type, ref, _timeout}}, call = {_type, _payload, context}}, _from, state) do
      Logger.warn fn -> "Redirecting Call #{inspect call_server}-#{inspect call, pretty: true}\n\n" end
      try do
        Logger.warn fn -> {"Redirecting Call #{inspect call_server}-#{inspect call, pretty: true}\n\n", Noizu.ElixirCore.CallingContext.metadata(context)} end
        # Clear lookup entry to allow system to assign correct entry and spawn new entry.
        call_server.worker_management().unregister!(ref, context, %{})
      rescue e -> Logger.error "[MessageProcessing] - Exception Raised #{inspect e}"
      catch e -> Logger.error "[MessageProcessing] - Exception Thrown #{inspect e}"
      end
      {:reply, {:s_retry, call_server, module}, state}
    end

    @doc """
    Catchall
    """
    def __handle_call(module, envelope, from, state), do: module.__call_handler(envelope, from, state)

    #-----------------------------------------------------
    # handle_cast
    #-----------------------------------------------------
    def __handle_cast(module, {:msg_redirect, {module, _delivery_details}, call = {_s, _call, _context}}, state), do: __handle_cast(module, call, state)
    def __handle_cast(_module, {:msg_redirect, {call_server, {call_type, ref, _timeout}}, call = {_type, payload, context}} = fc, state) do
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

    def __handle_cast(module, {:msg_envelope, {module, _delivery_details}, call = {_s, _call, _context}}, state), do: __handle_cast(module, call, state)
    def __handle_cast(_module, {:msg_envelope, {call_server, {call_type, ref, _timeout}}, call = {_type, payload, context}}, state) do
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
    def __handle_cast(module, envelope, state), do: module.__cast_handler(envelope, state)

    #-----------------------------------------------------
    # handle_info
    #-----------------------------------------------------
    def __handle_info(module, {:msg_redirect, {module, _delivery_details}, call = {_s, _call, _context}}, state), do: __handle_info(module, call, state)
    def __handle_info(_module, {:msg_redirect, {call_server, {call_type, ref, _timeout}}, call = {_type, payload, context}} = fc, state) do
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

    def __handle_info(module, {:msg_envelope, {module, _delivery_details}, call = {_s, _call, _context}}, state), do: __handle_info(module, call, state)
    def __handle_info(_module, {:msg_envelope, {call_server, {call_type, ref, _timeout}}, call = {_type, payload, context}}, state) do
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
    def __handle_info(module, envelope, state), do: module.__info_handler(envelope, state)

    #===============================================================================================================
    # Default delegation
    #===============================================================================================================
    def __call_router_catchall(module, envelope, _from, state) do
      Logger.error("#{module}.call_catchall - uncaught #{inspect envelope}")
      {:reply, :error, state}
    end
    def __cast_router_catchall(module, envelope, state) do
      Logger.error("#{module}.cast_catchall - uncaught #{inspect envelope}")
      {:noreply, state}
    end
    def __info_router_catchall(module, envelope, state) do
      Logger.error("#{module}.info_catchall - uncaught #{inspect envelope}")
      {:noreply, state}
    end




    def __delegate_call_handler(m, envelope = {_, _call, context}, from, %Noizu.SimplePool.Worker.State{initialized: :delayed_init} = state) do
      __delegate_call_handler(m, envelope, from, m.delayed_init(state, context))
    end
    def __delegate_call_handler(m, envelope = {_, _call, context}, from, %Noizu.SimplePool.Worker.State{initialized: false} = state) do
      case m.pool_worker_state_entity().load(state.worker_ref, context, %{}) do
        nil -> {:reply, :error, state}
        inner_state -> __delegate_call_handler(m, envelope, from, %Noizu.SimplePool.Worker.State{state| initialized: true, inner_state: inner_state})
      end
    end
    def __delegate_call_handler(m, envelope, from, state) do
      if m.meta()[:inactivity_check] do
        l = :os.system_time(:seconds)
        case state.inner_state.__struct__.__call_handler(envelope, from, state.inner_state) do
          {:reply, response, inner_state} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:reply, response, inner_state, hibernate} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
          {:stop, reason, inner_state} -> {:stop, reason, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:stop, reason, response, inner_state} -> {:stop, reason, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:noreply, inner_state} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
        end
      else
        case state.inner_state.__struct__.__call_handler(envelope, from, state.inner_state) do
          {:reply, response, inner_state} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:reply, response, inner_state, hibernate} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}, hibernate}
          {:stop, reason, inner_state} -> {:stop, reason, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:stop, reason, response, inner_state} -> {:stop, reason, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:noreply, inner_state} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}, hibernate}
        end
      end
    end

    def __delegate_cast_handler(m, envelope = {_, _call, context}, %Noizu.SimplePool.Worker.State{initialized: :delayed_init} = state) do
      __delegate_cast_handler(m, envelope, m.delayed_init(state, context))
    end
    def __delegate_cast_handler(m, envelope = {_, _call, context}, %Noizu.SimplePool.Worker.State{initialized: false} = state) do
      case m.pool_worker_state_entity().load(state.worker_ref, context, %{}) do
        nil -> {:noreply, state}
        inner_state -> __delegate_cast_handler(m, envelope, %Noizu.SimplePool.Worker.State{state| initialized: true, inner_state: inner_state})
      end
    end
    def __delegate_cast_handler(m, envelope, state) do
      if m.meta()[:inactivity_check] do
        l = :os.system_time(:seconds)
        case state.inner_state.__struct__.__cast_handler(envelope, state.inner_state) do
          {:reply, response, inner_state} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:reply, response, inner_state, hibernate} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
          {:stop, reason, inner_state} -> {:stop, reason, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:stop, reason, response, inner_state} -> {:stop, reason, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:noreply, inner_state} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
        end
      else
        case state.inner_state.__struct__.__cast_handler(envelope, state.inner_state) do
          {:reply, response, inner_state} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:reply, response, inner_state, hibernate} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}, hibernate}
          {:stop, reason, inner_state} -> {:stop, reason, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:stop, reason, response, inner_state} -> {:stop, reason, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:noreply, inner_state} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}, hibernate}
        end
      end
    end

    def __delegate_info_handler(m, envelope = {_, _call, context}, %Noizu.SimplePool.Worker.State{initialized: :delayed_init} = state) do
      __delegate_info_handler(m, envelope, m.delayed_init(state, context))
    end
    def __delegate_info_handler(m, envelope = {_, _call, context}, %Noizu.SimplePool.Worker.State{initialized: false} = state) do
      case m.pool_worker_state_entity().load(state.worker_ref, context, %{}) do
        nil -> {:noreply, state}
        inner_state -> __delegate_info_handler(m, envelope, %Noizu.SimplePool.Worker.State{state| initialized: true, inner_state: inner_state})
      end
    end
    def __delegate_info_handler(m, envelope, state) do
      if m.meta()[:inactivity_check] do
        l = :os.system_time(:seconds)
        case state.inner_state.__struct__.__info_handler(envelope, state.inner_state) do
          {:reply, response, inner_state} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:reply, response, inner_state, hibernate} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
          {:stop, reason, inner_state} -> {:stop, reason, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:stop, reason, response, inner_state} -> {:stop, reason, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:noreply, inner_state} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}}
          {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state, last_activity: l}, hibernate}
        end
      else
        case state.inner_state.__struct__.__info_handler(envelope, state.inner_state) do
          {:reply, response, inner_state} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:reply, response, inner_state, hibernate} -> {:reply, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}, hibernate}
          {:stop, reason, inner_state} -> {:stop, reason, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:stop, reason, response, inner_state} -> {:stop, reason, response, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:noreply, inner_state} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}}
          {:noreply, inner_state, hibernate} -> {:noreply, %Noizu.SimplePool.Worker.State{state| inner_state: inner_state}, hibernate}
        end
      end
    end

  end



  defmodule DefaultProvider do
    defmacro __using__(_options) do
      quote do
        require Logger
        @module __MODULE__
        @behaviour Noizu.SimplePool.V2.MessageProcessingBehaviour
        alias Noizu.SimplePool.V2.MessageProcessingBehaviour.Default
        #===============================================================================================================
        # Call routing
        #===============================================================================================================

        #----------------
        # call routing
        #----------------
        def handle_call(msg, from, state), do: Default.__handle_call(__MODULE__, msg, from, state)
        def call_router_user(_msg, _from, _state), do: nil
        def call_router_internal(_msg, _from, _state), do: nil
        def call_router_catchall(msg, from, state), do: Default.__call_router_catchall(__MODULE__, msg, from, state)
        def __call_handler(msg, from, state) do
          call_router_user(msg, from, state) || call_router_internal(msg, from, state) || call_router_catchall(msg, from, state)
        end

        #----------------
        # cast routing
        #----------------
        def handle_cast(msg, state), do: Default.__handle_cast(__MODULE__, msg, state)
        def cast_router_user(_msg, _state), do: nil
        def cast_router_internal(_msg, _state), do: nil
        def cast_router_catchall(msg, state), do: Default.__cast_router_catchall(__MODULE__, msg, state)
        def __cast_handler(msg, state) do
          cast_router_user(msg, state) || cast_router_internal(msg, state) || cast_router_catchall(msg, state)
        end

        #----------------
        # info routing
        #----------------
        def handle_info(msg, state), do: Default.__handle_info(__MODULE__, msg, state)
        def info_router_user(_msg, _state), do: nil
        def info_router_internal(_msg, _state), do: nil
        def info_router_catchall(msg, state), do: Default.__info_router_catchall(__MODULE__, msg, state)
        def __info_handler(msg, state) do
          info_router_user(msg, state) || info_router_internal(msg, state) || info_router_catchall(msg, state)
        end

        #===============================================================================================================
        # Overridable
        #===============================================================================================================
        defoverridable [
          # call routing
          call_router_user: 3,
          call_router_internal: 3,
          call_router_catchall: 3,
          __call_handler: 3,

          # cast routing
          cast_router_user: 2,
          cast_router_internal: 2,
          cast_router_catchall: 2,
          __cast_handler: 2,

          # info routing
          info_router_user: 2,
          info_router_internal: 2,
          info_router_catchall: 2,
          __info_handler: 2,
        ]
      end
    end
  end
end