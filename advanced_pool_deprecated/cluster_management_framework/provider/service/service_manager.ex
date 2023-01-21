#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.AdvancedPool.V3.ClusterManagementFramework.Cluster.ServiceManager do
  @moduledoc """
     The service monitor is responsible for monitoring health of a service spanning one or more nodes and coordinating rebalances, shutdowns and other activities.
  """
  use Noizu.AdvancedPool.PoolBehaviour,
      default_modules: [:pool_supervisor, :monitor],
      worker_state_entity: Noizu.AdvancedPool.V3.ClusterManagementFramework.Cluster.ServiceManager.WorkerEntity,
      verbose: false

  #=======================================================
  # Service Operations and Calls
  #=======================================================

  #--------------------------
  # service_health_report/3
  #--------------------------
  def service_health_report(service, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.get!(service, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.cached(service, context)
    c && c.health_report
  end

  #--------------------------
  # service_status/3
  #--------------------------
  def service_status(service, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.get!(service, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.cached(service, context)
    c && c.status
  end

  #--------------------------
  # service_state/3
  #--------------------------
  def service_state(service, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.get!(service, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.cached(service, context)
    c && c.state
  end

  #--------------------------
  # pending_state/3
  #--------------------------
  def service_pending_state(service, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.get!(service, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.cached(service, context)
    c && c.pending_state
  end

  #--------------------------
  # service_definition/3
  #--------------------------
  defdelegate service_definition(service, context, options \\ %{}), to: Noizu.AdvancedPool.V3.ClusterManagementFramework.ClusterManager

  #--------------------------
  # service_status_details/3
  #--------------------------
  def service_status_details(service, context, _options) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.get!(service, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.cached(service, context)
    c && c.status_details
  end

  #--------------------------
  # block_for_service_state/5
  #--------------------------
  defdelegate block_for_service_state(service, desired_state, context, options, timeout \\ :infinity), to: Noizu.AdvancedPool.V3.ClusterManagementFramework.ClusterManager

  #--------------------------
  # block_for_service_status/5
  #--------------------------
  defdelegate block_for_service_status(service, desired_status, context, options, timeout \\ :infinity), to: Noizu.AdvancedPool.V3.ClusterManagementFramework.ClusterManager

  #--------------------------
  # lock_service/3
  #--------------------------
  def lock_service(service, instructions, context), do: __MODULE__.Server.Router.s_call!(service, {:lock_service, service, instructions}, context)

  #--------------------------
  # release_service/3
  #--------------------------
  def release_service(service, instructions, context), do: __MODULE__.Server.Router.s_call!(service, {:release_service, service, instructions}, context)

  #--------------------------
  # register_service/4
  #--------------------------
  def register_service(service, service_definition, instructions, context), do: __MODULE__.Server.Router.s_call!(service, {:register_service, service, service_definition, instructions}, context)

  #--------------------------
  # bring_service_online/3
  #--------------------------
  def bring_service_online(service, instructions, context), do: __MODULE__.Server.Router.s_call!(service, {:bring_service_online, service, instructions}, context)

  #--------------------------
  # take_service_offline/3
  #--------------------------
  def take_service_offline(service, instructions, context), do: __MODULE__.Server.Router.s_call!(service, {:take_service_offline, service, instructions}, context)

  #--------------------------
  # rebalance_service/3
  #--------------------------
  def rebalance_service(service, instructions, context), do: __MODULE__.Server.Router.s_call!(service, {:rebalance_service, service, instructions}, context)



  #=======================================================
  # Service Instance Operations and Calls
  #=======================================================

  #--------------------------
  # service_instance_health_report/4
  #--------------------------
  def service_instance_health_report(service, instance, context, options \\ %{}) do
    service.node_manager().service_instance_health_report(instance, service, context, options)
  end

  #--------------------------
  # service_instance_status/4
  #--------------------------
  def service_instance_status(service, instance, context, options \\ %{}) do
    service.node_manager().service_instance_status(instance, service, context, options)
  end

  #--------------------------
  # service_instance_state/4
  #--------------------------
  def service_instance_state(service, instance, context, options \\ %{}) do
    service.node_manager().service_instance_state(instance, service, context, options)
  end

  #--------------------------
  # service_instance_pending_state/4
  #--------------------------
  def service_instance_pending_state(service, instance, context, options \\ %{}) do
    service.node_manager().service_instance_pending_state(instance, service, context, options)
  end

  #--------------------------
  # service_instance_definition/4
  #--------------------------
  def service_instance_definition(service, instance, context, options \\ %{}) do
    c = cond do
      options[:cache] == false -> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.get!(service, context, options)
      true -> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.get!(service, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.cached(service, context)
    end
    c && c.instance_definitions[instance]
  end

  #--------------------------
  # service_instance_status_details/4
  #--------------------------
  def service_instance_status_details(service, instance, context, options) do
    service.node_manager().service_instance_status_details(instance, service, context, options)
  end

  #--------------------------
  # block_for_service_instance_state/5
  #--------------------------
  def block_for_service_instance_state(service, instance, desired_state, context, options, timeout \\ :infinity)
  def block_for_service_instance_state(service, instance, desired_state, context, options, timeout)  when is_atom(desired_state), do: block_for_service_instance_state(service, instance, [desired_state], context, options, timeout)
  def block_for_service_instance_state(service, instance, desired_states, context, options, timeout) when is_list(desired_states) do
    wait_for_condition(
      fn ->
        s = service_instance_state(service, instance, context, options)
        Enum.member?(desired_states, s) && {:ok, s}
      end, timeout)
  end

  #--------------------------
  # block_for_service_status/5
  #--------------------------
  def block_for_service_instance_status(service, instance, desired_status, context, options, timeout \\ :infinity)
  def block_for_service_instance_status(service, instance, desired_status, context, options, timeout)  when is_atom(desired_status), do: block_for_service_instance_status(service, instance, [desired_status], context, options, timeout)
  def block_for_service_instance_status(service, instance, desired_statuses, context, options, timeout) when is_list(desired_statuses) do
    wait_for_condition(
      fn ->
        s = service_instance_status(service, instance, context, options)
        Enum.member?(desired_statuses, s) && {:ok, s}
      end, timeout)
  end

  #--------------------------
  # lock_service/4
  #--------------------------
  def lock_service_instance(service, instance, instructions, context), do: __MODULE__.Server.Router.s_call!(service, {:lock_service_instance, instance, instructions}, context)

  #--------------------------
  # release_service/4
  #--------------------------
  def release_service_instance(service, instance, instructions, context), do: __MODULE__.Server.Router.s_call!(service, {:release_service_instance, instance, instructions}, context)

  #--------------------------
  # bring_service_instance_online/4
  #--------------------------
  def bring_service_instance_online(service, instance, instructions, context), do: __MODULE__.Server.Router.s_call!(service, {:bring_service_instance_online, instance, instructions}, context)

  #--------------------------
  # take_service_instance_offline/4
  #--------------------------
  def take_service_instance_offline(service, instance, instructions, context), do: __MODULE__.Server.Router.s_call!(service, {:take_service_instance_offline, instance, instructions}, context)

  #--------------------------
  # select_host/4
  #--------------------------
  def select_host(service, _ref, context, _opts \\ %{}) do
    # Temporary rough logic, needs to check for service instance/node status, lock status, weight, health, etc.
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.cached(service, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.cached(service, context)
    instances = (c && c.instance_definitions || %{}) |> Enum.map(fn({k, _v}) -> k end)
    case Enum.take_random(instances, 1) do
      [n] -> {:ack, n}
      _ -> {:nack, :no_available_hosts}
    end
  end

  #--------------------------
  # hosts/2
  #--------------------------
  def hosts(service, context) do
    # Temporary rough logic, needs to check for service instance/node status, lock status, weight, health, etc.
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.cached(service, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Repo.cached(service, context)
    (c && c.instance_definitions || %{}) |> Enum.map(fn({k, _v}) -> k end)
  end

  #======================================================
  # Server Module
  #======================================================
  defmodule Server do
    @vsn 1.0
    alias Noizu.AdvancedPool.V3.Server.State

    use Noizu.AdvancedPool.V3.ServerBehaviour,
        worker_state_entity: nil

    require Logger

    #-----------------------------
    # initial_state/2
    #-----------------------------
    def initial_state([service, configuration], context) do
      # @TODO exception handling

      service_state = case Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Entity.entity!(service) do
        v =  %Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Entity{} ->
          v
          |> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Entity.reset(context, configuration)
          |> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.update!(context)
        _ -> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.State.Entity.ref(service)
      end

      # @TODO setup heart beat for background processing.
      %State{
        pool: pool(),
        entity: service_state,
        status_details: :initialized,
        extended: %{},
        environment_details: %{},
        options: option_settings()
      }
    end

    #-----------------------------
    # cluster_heart_beat/2
    #-----------------------------
    def cluster_heart_beat(state, _context) do
      # @todo update reports, send alert messages, etc.
      {:noreply, state}
    end

    #-----------------------------
    # call handlers
    #-----------------------------
    def call__lock_service(state,  _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__release_service(state,  _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__register_service(state,  _service, _service_definition, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__bring_service_online(state, _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__take_service_offline(state, _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__rebalance_service(state, _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__lock_service_instance(state,  _instance, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__release_service_instance(state, _instance, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__bring_service_instance_online(state, _instance, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__take_service_instance_offline(state, _instance, _instructions, _context), do: {:reply, :feature_pending, state}

    #-----------------------------
    # info handlers
    #-----------------------------
    def info__process_service_down_event(reference, process, reason, state) do
      cond do
        state.entity == nil ->
          Logger.error "[ServiceDown] Unknown State.Entity."
          {:noreply, state}
        rl = state.entity.meta[:monitor_lookup][reference] ->
          Logger.error "[ServiceDown] Service Has Stopped #{rl}."
          {:noreply, state}
        true ->
          Logger.error "[ServiceDown] Unknown DownLink #{inspect {reference, process, reason}}."
          {:noreply, state}
      end
    end


    #------------------------------------------------------------------------
    # call router
    #------------------------------------------------------------------------
    def __handle_call__({:spawn, envelope}, from, state), do: __handle_call__(envelope, from, state)
    def __handle_call__({:passive, envelope}, from, state), do: __handle_call__(envelope, from, state)
    def __handle_call__({:s, {:lock_service,  service, instructions}, context}, _from, state), do: call__lock_service(state,  service, instructions, context)
    def __handle_call__({:s, {:release_service,  service, instructions}, context}, _from, state), do: call__release_service(state,  service, instructions, context)
    def __handle_call__({:s, {:register_service,  service, service_definition, instructions}, context}, _from, state), do: call__register_service(state,  service, service_definition, instructions, context)
    def __handle_call__({:s, {:bring_service_online,  service, instructions}, context}, _from, state), do: call__bring_service_online(state,  service, instructions, context)
    def __handle_call__({:s, {:take_service_offline,  service, instructions}, context}, _from, state), do: call__take_service_offline(state,  service, instructions, context)
    def __handle_call__({:s, {:rebalance_service,  service, instructions}, context}, _from, state), do: call__rebalance_service(state,  service, instructions, context)
    def __handle_call__({:s, {:lock_service_instance,  instance, instructions}, context}, _from, state), do: call__lock_service_instance(state,  instance, instructions, context)
    def __handle_call__({:s, {:release_service_instance,  instance, instructions}, context}, _from, state), do: call__release_service_instance(state,  instance, instructions, context)
    def __handle_call__({:s, {:bring_service_instance_online,  instance, instructions}, context}, _from, state), do: call__bring_service_instance_online(state,  instance, instructions, context)
    def __handle_call__({:s, {:take_service_instance_offline,  instance, instructions}, context}, _from, state), do: call__take_service_instance_offline(state,  instance, instructions, context)
    def __handle_call__(call, from, state), do: super(call, from, state)

    #------------------------------------------------------------------------
    # info router
    #------------------------------------------------------------------------
    def __handle_info__({:spawn, envelope}, state), do: __handle_info__(envelope, state)
    def __handle_info__({:passive, envelope}, state), do: __handle_info__(envelope, state)
    def __handle_info__({:DOWN, reference, :process, process, reason}, state), do: info__process_service_down_event(reference, process, reason, state)
    def __handle_info__(call, state), do: super(call, state)

  end # end defmodule Server
end
