#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.AdvancedPool.V3.ClusterManagementFramework.ClusterManager do
  @moduledoc """
     The cluster manager is responsible for monitoring multiple services spanning multiple nodes and provides the entry point for grabbing current cluster status info.
  """

  use Noizu.AdvancedPool.V3.StandAloneServiceBehaviour,
      default_modules: [:pool_supervisor, :monitor],
      worker_state_entity: nil,
      verbose: false

  @cluster :default_cluster


  #=======================================================
  # Cluster Operations and Calls
  #=======================================================

  #--------------------------
  # health_report/1
  #--------------------------
  def health_report(context) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.cached(@cluster, context)
    c && c.health_report
  end

  #--------------------------
  # status/1
  #--------------------------
  def status(context) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.cached(@cluster, context)
    c && c.status
  end

  #--------------------------
  # state/1
  #--------------------------
  def state(context) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.cached(@cluster, context)
    c && c.state
  end

  #--------------------------
  # pending_state/1
  #--------------------------
  def pending_state(context) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.cached(@cluster, context)
    c && c.pending_state
  end


  #--------------------------
  # status_details/2
  #--------------------------
  def status_details(context, _options) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.cached(@cluster, context)
    c && c.status_details
  end

  #--------------------------
  # block_for_state/3
  #--------------------------
  def block_for_state(desired_state, context, timeout \\ :infinity)
  def block_for_state(desired_state, context, timeout)  when is_atom(desired_state), do: block_for_state([desired_state], context, timeout)
  def block_for_state(desired_states, context, timeout) when is_list(desired_states) do
    wait_for_condition(
      fn ->
        s = state(context)
        Enum.member?(desired_states, s) && {:ok, s}
      end, timeout)
  end

  #--------------------------
  # block_for_status/3
  #--------------------------
  def block_for_status(desired_status, context, timeout \\ :infinity)
  def block_for_status(desired_status, context, timeout)  when is_atom(desired_status), do: block_for_status([desired_status], context, timeout)
  def block_for_status(desired_statuses, context, timeout) when is_list(desired_statuses) do
    wait_for_condition(
      fn ->
        s = status(context)
        Enum.member?(desired_statuses, s) && {:ok, s}
      end, timeout)
  end

  #--------------------------
  # manager_tenancy()
  #--------------------------
  def cluster_manager_tenancy() do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Entity.entity!(@cluster) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.cached(@cluster, context)
    c && c.node
  end

  #--------------------------
  # lock_cluster/2
  #--------------------------
  def lock_cluster(instructions, context), do: (c = cluster_manager_tenancy()) && __MODULE__.Server.Router.remote_system_call(c, {:lock_cluster, instructions}, context)


  #--------------------------
  # release_cluster/2
  #--------------------------
  def release_cluster(instructions, context), do: (c = cluster_manager_tenancy()) && __MODULE__.Server.Router.remote_system_call(c,  {:release_cluster, instructions}, context)


  #--------------------------
  # bring_cluster_online/2
  #--------------------------
  def bring_cluster_online(instructions, context), do: (c = cluster_manager_tenancy()) && __MODULE__.Server.Router.remote_system_call(c,  {:bring_cluster_online, instructions}, context)

  #--------------------------
  # take_cluster_offline/2
  #--------------------------
  def take_cluster_offline(instructions, context), do: (c = cluster_manager_tenancy()) && __MODULE__.Server.Router.remote_system_call(c,  {:bring_cluster_online, instructions}, context)

  #--------------------------
  # rebalance_cluster/2
  #--------------------------
  def rebalance_cluster(instructions, context), do: (c = cluster_manager_tenancy()) && __MODULE__.Server.Router.remote_system_call(c,  {:rebalance_cluster, instructions}, context)

  #--------------------------
  # log_telemetry/2
  #--------------------------
  def log_telemetry(telemetry, context) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.cached(@cluster, context)
    c && c.telemetry_handler && c.telemetry_handler.log_telemetry({{:cluster, @cluster}, telemetry}, c)
  end

  #--------------------------
  # log_event/4
  #--------------------------
  def log_event(level, event, detail, context) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.cached(@cluster, context)
    subject = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Entity.ref(@cluster)
    c && c.event_handler && c.event_handler.log_event(subject, level, event, detail, context)
  end

  #=======================================================
  # Service Operations and Calls
  #=======================================================

  #--------------------------
  # service_health_report/3
  #--------------------------
  def service_health_report(service, context, options \\ %{}) do
    service.service_manager().health_report(service, context, options)
  end

  #--------------------------
  # service_status/3
  #--------------------------
  def service_status(service, context, options \\ %{}) do
    service.service_manager().status(service, context, options)
  end

  #--------------------------
  # service_state/3
  #--------------------------
  def service_state(service, context, options \\ %{}) do
    service.service_manager().state(service, context, options)
  end

  #--------------------------
  # pending_state/3
  #--------------------------
  def service_pending_state(service, context, options \\ %{}) do
    service.service_manager().pending_state(service, context, options)
  end


  #--------------------------
  # service_definitions/2
  #--------------------------
  def service_definitions(context, options \\ %{}) do
    c = cond do
      options[:cache] == false -> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context)
      true -> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.cached(@cluster, context, options)
    end
    c && c.service_definitions
  end

  #--------------------------
  # service_definition/3
  #--------------------------
  def service_definition(service, context, options \\ %{}) do
    c = cond do
      options[:cache] == false -> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context)
      true -> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.cached(@cluster, context, options)
    end
    c && c.service_definitions[service]
  end

  #--------------------------
  # services_status_details/2
  #--------------------------
  def services_status_details(context, options \\ %{}) do
    c = cond do
      options[:cache] == false -> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context)
      true -> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.get!(@cluster, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.cached(@cluster, context, options)
    end
    c && c.service_statuses
  end

  #--------------------------
  # service_status_details/3
  #--------------------------
  def service_status_details(service, context, options) do
    service.service_manager().status_details(service, context, options)
  end

  #--------------------------
  # block_for_service_state/5
  #--------------------------
  def block_for_service_state(service, desired_state, context, options, timeout \\ :infinity)
  def block_for_service_state(service, desired_state, context, options, timeout)  when is_atom(desired_state), do: block_for_service_state(service, [desired_state], context, options, timeout)
  def block_for_service_state(service, desired_states, context, options, timeout) when is_list(desired_states) do
    wait_for_condition(
      fn ->
        s = service_state(service, context, options)
        Enum.member?(desired_states, s) && {:ok, s}
      end, timeout)
  end

  #--------------------------
  # block_for_service_status/5
  #--------------------------
  def block_for_service_status(service, desired_status, context, options, timeout \\ :infinity)
  def block_for_service_status(service, desired_status, context, options, timeout)  when is_atom(desired_status), do: block_for_service_status(service, [desired_status], context, options, timeout)
  def block_for_service_status(service, desired_statuses, context, options, timeout) when is_list(desired_statuses) do
    wait_for_condition(
      fn ->
        s = service_status(service, context, options)
        Enum.member?(desired_statuses, s) && {:ok, s}
      end, timeout)
  end

  #--------------------------
  # lock_service/3
  #--------------------------
  def lock_service(service, instructions, context), do: (c = cluster_manager_tenancy()) && __MODULE__.Server.Router.remote_system_call(c,  {:lock_service, service, instructions}, context)

  #--------------------------
  # release_service/3
  #--------------------------
  def release_service(service, instructions, context), do: (c = cluster_manager_tenancy()) && __MODULE__.Server.Router.remote_system_call(c,  {:release_service, service, instructions}, context)

  #--------------------------
  # register_service/4
  #--------------------------
  def register_service(service, service_definition, instructions, context), do: (c = cluster_manager_tenancy()) && __MODULE__.Server.Router.remote_system_call(c,  {:register_service, service, service_definition, instructions}, context)

  #--------------------------
  # bring_service_online/3
  #--------------------------
  def bring_service_online(service, instructions, context), do: (c = cluster_manager_tenancy()) && __MODULE__.Server.Router.remote_system_call(c,  {:bring_service_online, service, instructions}, context)

  #--------------------------
  # take_service_offline/3
  #--------------------------
  def take_service_offline(service, instructions, context), do: (c = cluster_manager_tenancy()) && __MODULE__.Server.Router.remote_system_call(c,  {:take_service_offline, service, instructions}, context)

  #--------------------------
  # rebalance_service/3
  #--------------------------
  def rebalance_service(service, instructions, context), do: (c = cluster_manager_tenancy()) && __MODULE__.Server.Router.remote_system_call(c,  {:rebalance_service, service, instructions}, context)

  #======================================================
  # Server Module
  #======================================================
  defmodule Server do
    @vsn 1.0
    alias Noizu.AdvancedPool.V3.Server.State

    use Noizu.AdvancedPool.V3.ServerBehaviour,
        worker_state_entity: nil
    require Logger
    @cluster :default_cluster
    #-----------------------------
    # initial_state/2
    #-----------------------------
    def initial_state(_configuration, context) do
      cluster_state = case  Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Entity.entity!(@cluster) do
        v =  %Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Entity{} ->
          v
          |> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Entity.reset(context)
          |> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.update!(context)
        _ -> nil
      end

      {:ok, h_ref} = :timer.send_after(5_000, self(), {:passive, {:i, {:cluster_heart_beat}, context}})

      %State{
        pool: pool(),
        entity: cluster_state,
        status_details: :initialized,
        extended: %{},
        environment_details: %{heart_beat: h_ref},
        options: option_settings()
      }
    end

    #-----------------------------
    # cluster_heart_beat/2
    #-----------------------------
    def info__cluster_heart_beat(state, context) do
      # @todo update reports, send alert messages, etc.
      # Logger.info("Cluster Heart Beat")
      {:ok, _h_ref} = :timer.send_after(5_000, self(), {:passive, {:i, {:cluster_heart_beat}, context}})
      {:noreply, state}
    end

    #-----------------------------
    # call handlers
    #-----------------------------
    def call__lock_cluster(state,  _instructions, _context), do: {:reply, :feature_pending, state}
    def call__release_cluster(state,  _instructions, _context), do: {:reply, :feature_pending, state}
    def call__bring_cluster_online(state,  _instructions, _context), do: {:reply, :feature_pending, state}
    def call__take_cluster_offline(state,  _instructions, _context), do: {:reply, :feature_pending, state}
    def call__rebalance_cluster(state,  _instructions, _context), do: {:reply, :feature_pending, state}
    def call__lock_service(state,  _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__release_service(state,  _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__register_service(state,  _service, _service_definition, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__bring_service_online(state,  _service, _instructions, context) do
      # Stub Logic
      state = state
              |> put_in([Access.key(:entity), Access.key(:status)], :green)
              |> put_in([Access.key(:entity), Access.key(:state)], :online)
      # Final logic pending - ping services and write records to inform services/nodes they need to report in. Once all have reported and are online change status and state. after timeout if missing coverage use :degraded status, :online state.

      Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.update!(state.entity, Noizu.ElixirCore.CallingContext.system(context))

      {:reply, :pending, state}
    end
    def call__take_service_offline(state,  _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__rebalance_service(state,  _service, _instructions, context)do
      # Stub Logic
      state = state
              |> put_in([Access.key(:entity), Access.key(:status)], :offline)
              |> put_in([Access.key(:entity), Access.key(:state)], :offline)
      # pending, coordinate with cluster manager and service definitions to determine what service instances need to be launched
      Noizu.AdvancedPool.V3.ClusterManagement.Cluster.State.Repo.update!(state.entity, Noizu.ElixirCore.CallingContext.system(context))

      {:reply, :pending, state}
    end

    #------------------------------------------------------------------------
    # call router
    #------------------------------------------------------------------------
    def __handle_call__({:spawn, envelope}, from, state), do: __handle_call__(envelope, from, state)
    def __handle_call__({:passive, envelope}, from, state), do: __handle_call__(envelope, from, state)
    def __handle_call__({:m, {:lock_cluster,  instructions}, context}, _from, state), do: call__lock_cluster(state,  instructions, context)
    def __handle_call__({:m, {:release_cluster,  instructions}, context}, _from, state), do: call__release_cluster(state,  instructions, context)
    def __handle_call__({:m, {:bring_cluster_online,  instructions}, context}, _from, state), do: call__bring_cluster_online(state,  instructions, context)
    def __handle_call__({:m, {:take_cluster_offline,  instructions}, context}, _from, state), do: call__take_cluster_offline(state,  instructions, context)
    def __handle_call__({:m, {:rebalance_cluster,  instructions}, context}, _from, state), do: call__rebalance_cluster(state,  instructions, context)
    def __handle_call__({:m, {:lock_service,  service, instructions}, context}, _from, state), do: call__lock_service(state,  service, instructions, context)
    def __handle_call__({:m, {:release_service,  service, instructions}, context}, _from, state), do: call__release_service(state,  service, instructions, context)
    def __handle_call__({:m, {:register_service,  service, service_definition, instructions}, context}, _from, state), do: call__register_service(state,  service, service_definition, instructions, context)
    def __handle_call__({:m, {:bring_service_online,  service, instructions}, context}, _from, state), do: call__bring_service_online(state,  service, instructions, context)
    def __handle_call__({:m, {:take_service_offline,  service, instructions}, context}, _from, state), do: call__take_service_offline(state,  service, instructions, context)
    def __handle_call__({:m, {:rebalance_service,  service, instructions}, context}, _from, state), do: call__rebalance_service(state,  service, instructions, context)
    def __handle_call__(call, from, state), do: super(call, from, state)


    def __handle_info__({:spawn, envelope}, state), do: __handle_info__(envelope, state)
    def __handle_info__({:passive, envelope}, state), do: __handle_info__(envelope, state)
    def __handle_info__({:i, {:cluster_heart_beat}, context}, state), do: info__cluster_heart_beat(state,  context)
    def __handle_info__(call, state), do: super(call, state)

  end # end defmodule Server
end
