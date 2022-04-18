#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.AdvancedPool.V3.ClusterManagementFramework.Cluster.NodeManager do

  use Noizu.AdvancedPool.V3.StandAloneServiceBehaviour,
      default_modules: [:pool_supervisor, :monitor],
      worker_state_entity: Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Entity,
      verbose: false


  #--------------------------
  # health_report/3
  #--------------------------
  def health_report(node, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.get!(node, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.cached(node, context)
    c && c.health_report
  end

  #--------------------------
  # status/3
  #--------------------------
  def status(node, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.get!(node, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.cached(node, context)
    c && c.status
  end

  #--------------------------
  # state/3
  #--------------------------
  def state(node, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.get!(node, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.cached(node, context)
    c && c.state
  end

  #--------------------------
  # pending_state/3
  #--------------------------
  def pending_state(node, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.get!(node, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.cached(node, context)
    c && c.pending_state
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
  # service_pending_state/3
  #--------------------------
  def service_pending_state(service, context, options \\ %{}) do
    service.service_manager().pending_state(service, context, options)
  end

  #--------------------------
  # service_instance_health_report/4
  #--------------------------
  def service_instance_health_report(service, node, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.get!(node, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.cached(node, context)
    c && c.service_instances_health_report[service]
  end

  #--------------------------
  # service_instance_status/4
  #--------------------------
  def service_instance_status(service, node, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.get!(node, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.cached(node, context)
    i = c && c.service_instances[service]
    i && i.status
  end

  #--------------------------
  # service_instance_state/4
  #--------------------------
  def service_instance_state(service, node, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.get!(node, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.cached(node, context)
    i = c && c.service_instances[service]
    i && i.state
  end

  #--------------------------
  # service_instance_pending_status/4
  #--------------------------
  def service_instance_pending_state(service, node, context, _options \\ %{}) do
    c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.get!(node, context) # c = Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.cached(node, context)
    i = c && c.service_instances[service]
    i && i.pending_state
  end

  #--------------------------
  # service_definition/3
  #--------------------------
  defdelegate service_definition(service, context, options \\ %{}), to: Noizu.AdvancedPool.V3.ClusterManagementFramework.ClusterManager

  #--------------------------
  # service_status_details/3
  #--------------------------
  defdelegate service_status_details(service, context, options \\ %{}), to: Noizu.AdvancedPool.V3.ClusterManagementFramework.ClusterManager

  #--------------------------
  # block_for_service_state/5
  #--------------------------
  defdelegate block_for_service_state(service, desired_state, context, options, timeout \\ :infinity), to: Noizu.AdvancedPool.V3.ClusterManagementFramework.ClusterManager

  #--------------------------
  # block_for_service_status/5
  #--------------------------
  defdelegate block_for_service_status(service, desired_status, context, options, timeout \\ :infinity), to: Noizu.AdvancedPool.V3.ClusterManagementFramework.ClusterManager

  #--------------------------
  # lock_service_instance/4
  #--------------------------
  def lock_service_instance(service, node, instructions, context), do: __MODULE__.Server.Router.remote_system_call(node, {:lock_service_instance, service, instructions}, context)

  #--------------------------
  # release_service_instance/4
  #--------------------------
  def release_service_instance(service, node, instructions, context), do: __MODULE__.Server.Router.remote_system_call(node, {:release_service_instance, service, instructions}, context)

  #--------------------------
  # bring_service_instance_online/4
  #--------------------------
  def bring_service_instance_online(service, node, instructions, context), do: __MODULE__.Server.Router.remote_system_call(node, {:bring_service_instance_online, service, instructions}, context)

  #--------------------------
  # take_service_instance_offline/4
  #--------------------------
  def take_service_instance_offline(service, node, instructions, context), do: __MODULE__.Server.Router.remote_system_call(node, {:take_service_instance_offline, service, instructions}, context)

  #--------------------------
  # lock_node/3
  #--------------------------
  def lock_node(node, instructions, context), do: __MODULE__.Server.Router.remote_system_call(node, {:lock_node, instructions}, context)

  #--------------------------
  # release_node/3
  #--------------------------
  def release_node(node, instructions, context), do: __MODULE__.Server.Router.remote_system_call(node, {:release_node, instructions}, context)

  #--------------------------
  # bring_node_online/2
  #--------------------------
  def bring_node_online(node, instructions, context), do: __MODULE__.Server.Router.remote_system_call(node, {:bring_node_online, instructions}, context)

  #--------------------------
  # take_node_offline/2
  #--------------------------
  def take_node_offline(node, instructions, context), do: __MODULE__.Server.Router.remote_system_call(node, {:take_node_offline, instructions}, context)


  #--------------------------
  # block_for_state/4
  #--------------------------
  def block_for_state(node, desired_state, context, timeout \\ :infinity)
  def block_for_state(node, desired_state, context, timeout)  when is_atom(desired_state), do: block_for_state(node, [desired_state], context, timeout)
  def block_for_state(node, desired_states, context, timeout) when is_list(desired_states) do
    wait_for_condition(
      fn ->
        s = state(node, context)
        Enum.member?(desired_states, s) && {:ok, s}
      end, timeout)
  end

  #--------------------------
  # block_for_status/4
  #--------------------------
  def block_for_status(node, desired_status, context, timeout \\ :infinity)
  def block_for_status(node, desired_status, context, timeout)  when is_atom(desired_status), do: block_for_status(node, [desired_status], context, timeout)
  def block_for_status(node, desired_statuses, context, timeout) when is_list(desired_statuses) do
    wait_for_condition(
      fn ->
        s = status(node, context)
        Enum.member?(desired_statuses, s) && {:ok, s}
      end, timeout)
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
    def initial_state({node_name, configuration}, context) do
      # @TODO exception handling

      node_state = case Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Entity.entity!(node_name) do
        v =  % Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Entity{} ->
          v
          |> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Entity.reset(context, configuration)
          |> Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.update!(context)
        _ -> %Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Entity{identifier: node_name}
      end
      IO.puts "NODE STATE = #{inspect node_state}"
      # @TODO setup heart beat for background processing.

      %State{
        pool: pool(),
        entity: node_state,
        status_details: :initialized,
        extended: %{},
        environment_details: %{},
        options: option_settings()
      }
    end

    #-----------------------------
    # node_heart_beat/2
    #-----------------------------
    def node_heart_beat(state, _context) do
      # @todo update reports, send alert messages, etc.
      {:noreply, state}
    end

    #-----------------------------
    # call handlers
    #-----------------------------
    def call__lock_service_instance(state,  _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__release_service_instance(state,  _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__bring_service_instance_online(state,  _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__take_service_instance_offline(state, _service, _instructions, _context), do: {:reply, :feature_pending, state}
    def call__lock_node(state,  _instructions, _context), do: {:reply, :feature_pending, state}
    def call__release_node(state,  _instructions, _context), do: {:reply, :feature_pending, state}

    def call__bring_node_online(state, _instructions, context, options \\ %{}) do
      # Simply walk through service definitions and find any keyed to this node.
      service_definitions = Noizu.AdvancedPool.V3.ClusterManagementFramework.ClusterManager.service_definitions(context) || %{}
      service_instances = Enum.map(service_definitions,
                            fn({service, _definition})->
                              # checks for online status, etc.
                              service.service_manager().service_instance_definition(service, state.entity.identifier, context, options)
                            end)
                          |> Enum.filter(fn(node_instance) -> (node_instance != nil) end)

      updated_statuses = Enum.reduce(service_instances || %{}, state.entity.service_instances_statuses || %{},
        fn(v, acc) ->
          # todo pass in options v.pool_settings
          case pool_supervisor().add_child_supervisor(v.service.pool_supervisor(), v.launch_parameters, context) do
            {:ok, pid} ->
              cond do
                acc[v.service] ->
                  acc
                  |> put_in([v.service, Access.key(:service_monitor)], Process.monitor(pid))
                  |> put_in([v.service, Access.key(:service_process)], pid)
                  |> put_in([v.service, Access.key(:service_error)], nil)
                  |> put_in([v.service, Access.key(:status)], :initializing)
                  |> put_in([v.service, Access.key(:state)], :initializing)
                  |> put_in([v.service, Access.key(:pending_state)], :online)
                  |> put_in([v.service, Access.key(:updated_on)], DateTime.utc_now())
                  |> put_in([v.service, Access.key(:state_changed_on)], DateTime.utc_now())
                  |> put_in([v.service, Access.key(:pending_state_changed_on)], DateTime.utc_now())
                true ->
                  put_in(acc, [v.service], Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.Instance.Status.new(v.service, state.entity.identifier, pid, nil))
                  |> put_in([v.service, Access.key(:status)], :initializing)
                  |> put_in([v.service, Access.key(:state)], :initializing)
                  |> put_in([v.service, Access.key(:pending_state)], :online)
              end
            e ->
              Logger.error("Problem starting Node Manager - #{inspect e}", Noizu.ElixirCore.CallingContext.metadata(context))
              cond do
                acc[v.service] ->
                  acc
                  |> put_in([v.service, Access.key(:service_monitor)], nil)
                  |> put_in([v.service, Access.key(:service_process)], nil)
                  |> put_in([v.service, Access.key(:service_error)], e)
                  |> put_in([v.service, Access.key(:status)], :error)
                  |> put_in([v.service, Access.key(:state)], :initializing)
                  |> put_in([v.service, Access.key(:pending_state)], :online)
                  |> put_in([v.service, Access.key(:updated_on)], DateTime.utc_now())
                  |> put_in([v.service, Access.key(:state_changed_on)], DateTime.utc_now())
                  |> put_in([v.service, Access.key(:pending_state_changed_on)], DateTime.utc_now())
                true ->
                  put_in(acc, [v.service], Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Service.Instance.Status.new(v.service, state.entity.identifier, nil, e))
                  |> put_in([v.service, Access.key(:status)], :error)
                  |> put_in([v.service, Access.key(:state)], :initializing)
                  |> put_in([v.service, Access.key(:pending_state)], :online)
              end
          end
        end
      )

      monitor_lookup = Enum.map(updated_statuses,  fn({k,v}) -> v.service_monitor && {v.service_monitor, k} end)
                       |> Enum.filter(&(&1 != nil))
                       |> Map.new()

      state = state
              |> put_in([Access.key(:entity), Access.key(:status)], :green)
              |> put_in([Access.key(:entity), Access.key(:state)], :online)
              |> put_in([Access.key(:entity), Access.key(:pending_state)], :none)
              |> put_in([Access.key(:entity), Access.key(:updated_on)], DateTime.utc_now())
              |> put_in([Access.key(:entity), Access.key(:state_changed_on)], DateTime.utc_now())
              |> put_in([Access.key(:entity), Access.key(:pending_state_changed_on)], DateTime.utc_now())
              |> put_in([Access.key(:entity), Access.key(:service_instances)], service_instances)
              |> put_in([Access.key(:entity), Access.key(:service_instances_statuses)], updated_statuses)
              |> put_in([Access.key(:entity), Access.key(:meta), Access.key(:monitor_lookup)], monitor_lookup)

      # pending, coordinate with cluster manager and service definitions to determine what service instances need to be launched
      Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.update!(state.entity, Noizu.ElixirCore.CallingContext.system(context))

      {:reply, :ok, state}
    end

    def call__take_node_offline(state, _instructions, context) do
      # Stub Logic
      state = state
              |> put_in([Access.key(:entity), Access.key(:status)], :offline)
              |> put_in([Access.key(:entity), Access.key(:state)], :offline)
              |> put_in([Access.key(:entity), Access.key(:pending_state)], :none)
              |> put_in([Access.key(:entity), Access.key(:updated_on)], DateTime.utc_now())
              |> put_in([Access.key(:entity), Access.key(:state_changed_on)], DateTime.utc_now())
              |> put_in([Access.key(:entity), Access.key(:pending_state_changed_on)], DateTime.utc_now())
      # pending, coordinate with cluster manager and service definitions to determine what service instances need to be launched

      Noizu.AdvancedPool.V3.ClusterManagement.Cluster.Node.State.Repo.update!(state.entity, Noizu.ElixirCore.CallingContext.system(context))
      {:reply, :ok, state}
    end

    #------------------------------------------------------------------------
    # call router
    #------------------------------------------------------------------------
    def __handle_call__({:spawn, envelope}, from, state), do: __handle_call__(envelope, from, state)
    def __handle_call__({:passive, envelope}, from, state), do: __handle_call__(envelope, from, state)
    def __handle_call__({:m, {:bring_node_online, instructions}, context}, from, state), do: call__bring_node_online(state, instructions, context)
    def __handle_call__({:m, {:take_node_offline, instructions}, context}, from, state), do: call__take_node_offline(state, instructions, context)
    def __handle_call__({:m, {:lock_service_instance,  service, instructions}, context}, from, state), do: call__lock_service_instance(state,  service, instructions, context)
    def __handle_call__({:m, {:release_service_instance,  service, instructions}, context}, from, state), do: call__release_service_instance(state,  service, instructions, context)
    def __handle_call__({:m, {:bring_service_instance_online,  service, instructions}, context}, from, state), do: call__bring_service_instance_online(state,  service, instructions, context)
    def __handle_call__({:m, {:take_service_instance_offline,  service, instructions}, context}, from, state), do: call__take_service_instance_offline(state,  service, instructions, context)
    def __handle_call__({:m, {:lock_node,  instructions}, context}, from, state), do: call__lock_node(state,  instructions, context)
    def __handle_call__({:m, {:release_node,  instructions}, context}, from, state), do: call__release_node(state,  instructions, context)
    def __handle_call__(call, from, state), do: super(call, from, state)

  end # end defmodule Server
end
