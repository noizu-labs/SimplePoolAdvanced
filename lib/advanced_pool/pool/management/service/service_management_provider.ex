#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

# @todo should be renamed Default and moved into behaviour definition for consistency.
defmodule Noizu.AdvancedPool.V3.ServiceManagement.ServiceManagementProvider do
  alias Noizu.AdvancedPool.V3.Server.State, as: ServerState
  require Logger

  @doc """
  Default Definition for Service
  """
  def default_definition(pool_server) do
    pool_server.meta()[:default_definition]
    |> put_in([Access.key(:time_stamp)], DateTime.utc_now())
  end

  @doc """
  Enable Server for handling services.
  """
  def enable_server!(_pool_server, _node), do: :pending # Not implemented for V1 either

  @doc """
  Disable Server for handling services.
  """
  def disable_server!(_pool_server, _node), do: :pending # Not implemented for V1 either

  @doc """
  Get status of Service
  """
  def status(pool_server, args \\ {}, context \\ nil), do: pool_server.router().internal_call({:status, args}, context)

  @doc """

  """
  def load_pool(pool_server, args \\ {}, context \\ nil, options \\ nil), do: pool_server.router().internal_system_call({:load_pool, args, options}, context)

  @doc """

  """
  def load_complete(_pool_server, %ServerState{} = this, _process, _context) do
    this
    |> put_in([Access.key(:status), Access.key(:loading)], :complete)
    |> put_in([Access.key(:status), Access.key(:state)], :ready)
    #|> put_in([Access.key(:environment_details), Access.key(:effective), Access.key(:status)], :online)
    #|> put_in([Access.key(:environment_details), Access.key(:effective), Access.key(:directive)], :online)
    |> put_in([Access.key(:extended), Access.key(:load_process)], nil)
  end

  @doc """

  """
  def load_begin(_pool_server, %ServerState{} = this, process, _context) do
    this
    |> put_in([Access.key(:status), Access.key(:loading)], :started)
    |> put_in([Access.key(:status), Access.key(:state)], :loading)
    #|> put_in([Access.key(:environment_details), Access.key(:effective), Access.key(:status)], :loading)
    #|> put_in([Access.key(:environment_details), Access.key(:effective), Access.key(:directive)], :loading)
    |> put_in([Access.key(:extended), Access.key(:load_process)], process)
  end


  @doc """
  Wait for service to reach target state.
  """
  def status_wait(pool_server, target_state, context, timeout \\ :infinity)
  def status_wait(pool_server, target_state, context, timeout) when is_atom(target_state) do
    status_wait(pool_server, MapSet.new([target_state]), context, timeout)
  end

  def status_wait(pool_server, target_state, context, timeout) when is_list(target_state) do
    status_wait(pool_server, MapSet.new(target_state), context, timeout)
  end

  def status_wait(pool_server, %MapSet{} = target_state, context, timeout) do
    if timeout == :infinity do
      case pool_server.service_management().entity_status(context) do
        {:ack, state} -> if MapSet.member?(target_state, state), do: state, else: status_wait(pool_server, target_state, context, timeout)
        _ -> status_wait(pool_server, target_state, context, timeout)
      end
    else
      ts = :os.system_time(:millisecond)
      case pool_server.service_management().entity_status(context, %{timeout: timeout}) do
        {:ack, state} ->
          if MapSet.member?(target_state, state) do
            state
          else
            t = timeout - (:os.system_time(:millisecond) - ts)
            if t > 0 do
              status_wait(pool_server, target_state, context, t)
            else
              {:timeout, state}
            end
          end
        v ->
          t = timeout - (:os.system_time(:millisecond) - ts)
          if t > 0 do
            status_wait(pool_server, target_state, context, t)
          else
            {:timeout, v}
          end
      end
    end
  end

  @doc """
  Get service status.
  """
  def entity_status(pool_server, context, options \\ %{}) do
    try do
      pool_server.router().internal_system_call({:status, {}, options}, context, options)
    catch
      :rescue, e ->
        case e do
          {:timeout, c} -> {:timeout, c}
          _ -> {:error, {:rescue, e}}
        end

      :exit, e ->
        case e do
          {:timeout, c} -> {:timeout, c}
          _ -> {:error, {:exit, e}}
        end
    end # end try
  end

  @doc """
  Kill Pool.
  """
  def server_kill!(pool_server, args \\ {}, context \\ nil, options \\ %{}), do: pool_server.router().internal_cast({:server_kill!, args, options}, context, options)

  @doc """
  Perform Service Health Check.
  """
  def service_health_check!(pool_server, %Noizu.ElixirCore.CallingContext{} = context) do
    pool_server.router().internal_system_call({:health_check!, {}, %{}}, context)
  end

  def service_health_check!(pool_server, health_check_options, %Noizu.ElixirCore.CallingContext{} = context) do
    pool_server.router().internal_system_call({:health_check!, health_check_options, %{}}, context)
  end

  def service_health_check!(pool_server, health_check_options, %Noizu.ElixirCore.CallingContext{} = context, options) do
    pool_server.router().internal_system_call({:health_check!, health_check_options, options}, context, options)
  end


  @doc """
  Record Service Event
  """
  def record_service_event!(pool_server, event, details, context, _options) do
    Logger.debug("Service Manager V2 record_service_event NYI| #{inspect pool_server}, #{inspect event}", Noizu.ElixirCore.CallingContext.metadata(context))
    :ok
  end

end
