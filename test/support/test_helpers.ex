#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SimplePoolAdvanced.TestHelpers do
  def unique_ref_v2(:one), do: {:ref, Noizu.SimplePoolAdvanced.Support.TestV3WorkerEntity, "test_#{inspect :os.system_time(:microsecond)}"}
  def unique_ref_v2(:two), do: {:ref, Noizu.SimplePoolAdvanced.Support.TestV3TwoWorkerEntity, "test_#{inspect :os.system_time(:microsecond)}"}
  def unique_ref_v2(:three), do: {:ref, Noizu.SimplePoolAdvanced.Support.TestV3ThreeWorkerEntity, "test_#{inspect :os.system_time(:microsecond)}"}

  require Logger
  @pool_options %{hard_limit: 250, soft_limit: 150, target: 100}


  #-------------------------
  # Helper Method
  #-------------------------
  def wait_for_db() do
    wait_for_condition(
      fn() ->
        Enum.member?(Amnesia.info(:running_db_nodes), :"second@127.0.0.1") && Enum.member?(Amnesia.info(:running_db_nodes), :"first@127.0.0.1")
      end,
      60 * 5)
  end

  def wait_for_init() do
    Amnesia.start
    _r = wait_for_condition(
      fn() ->
        Enum.member?(Amnesia.info(:running_db_nodes), :"second@127.0.0.1")
      end,
      60 * 5)
  end

  def wait_for_condition(condition, timeout \\ :infinity) do
    cond do
      !is_function(condition, 0) -> {:error, :condition_not_callable}
      is_integer(timeout) -> wait_for_condition_inner(condition, :os.system_time(:seconds) + timeout)
      timeout == :infinity -> wait_for_condition_inner(condition, timeout)
      true ->  {:error, :invalid_timeout}
    end
  end

  def wait_for_condition_inner(condition, timeout) do
    check = condition.()
    cond do
      check == :ok || check == true -> :ok
      is_integer(timeout) && timeout < :os.system_time(:seconds) -> {:error, :timeout}
      true ->
        Process.sleep(100)
        wait_for_condition_inner(condition, timeout)
    end
  end



  def wait_hint_release(ref, service, context, timeout \\ 60_000) do
    t = :os.system_time(:millisecond)
    Process.sleep(100)
    case Noizu.SimplePoolAdvanced.WorkerLookupBehaviour.Dynamic.host!(ref, service, context) do
      {:ack, _h} -> :ok
      _j ->
        t2 = :os.system_time(:millisecond)
        t3 = timeout - (t2 - t)
        if t3 > 0 do
          wait_hint_release(ref, service, context, t3)
        else
          :timeout
        end

    end
  end

  def wait_hint_lock(ref, service, context, timeout \\ 60_000) do
    t = :os.system_time(:millisecond)
    Process.sleep(100)
    case Noizu.SimplePoolAdvanced.WorkerLookupBehaviour.Dynamic.host!(ref, service, context) do
      {:ack, _h} ->
        t2 = :os.system_time(:millisecond)
        t3 = timeout - (t2 - t)
        if t3 > 0 do
          wait_hint_lock(ref, service, context, t3)
        else
          :timeout
        end
      _j -> :ok
    end
  end

  def configure_test_cluster(context, _telemetry_handler, _event_handler) do

    telemetry_handler = nil
    event_handler = nil


    #----------------------------------------------------------------
    # Populate Service and Instance Configuration
    #----------------------------------------------------------------

    #-------------------------------------
    # test_service_one
    #-------------------------------------
    service = Noizu.SimplePoolAdvanced.Support.TestV3Pool
    test_service_one = Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Definition.new(service, %{min: 1, max: 3, target: 2}, %{min: 1, max: 3, target: 2})
    test_service_one_status = %Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Status{
      service: service,
      instances: %{
        :"first@127.0.0.1" => Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Instance.Status.new(service, :"first@127.0.0.1", nil, nil),
        :"second@127.0.0.1" => Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Instance.Status.new(service, :"second@127.0.0.1", nil, nil),
      },
      health_report: Noizu.SimplePoolAdvanced.V3.ClusterManagement.HealthReport.new({:ref, Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Entity, service}),
    }
    %Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Entity{
      identifier: service,
      service_definition: test_service_one,
      status_details: test_service_one_status,
      instance_definitions: %{
        :"first@127.0.0.1" => Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Instance.Definition.new(service, :"first@127.0.0.1", %{min: 1, max: 3, target: 2}, 1.0),
        :"second@127.0.0.1" => Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Instance.Definition.new(service, :"second@127.0.0.1", %{min: 1, max: 3, target: 2}, 0.5)
      },
      instance_statuses: %{}, # pending
      health_report: Noizu.SimplePoolAdvanced.V3.ClusterManagement.HealthReport.new({:ref, Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Entity, service}),
      telemetry_handler: telemetry_handler,
      event_handler: event_handler,
    } |> Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Repo.create!(context)

    #-------------------------------------
    # test_service_two
    #-------------------------------------
    service = Noizu.SimplePoolAdvanced.Support.TestV3TwoPool
    test_service_two = Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Definition.new(service, %{min: 1, max: 3, target: 2}, %{min: 1, max: 3, target: 2})
    test_service_two_status = %Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Status{
      service: service,
      instances: %{
        :"second@127.0.0.1" => Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Instance.Status.new(service, :"second@127.0.0.1", nil, nil),
      },
      health_report: Noizu.SimplePoolAdvanced.V3.ClusterManagement.HealthReport.new({:ref, Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Entity, service}),
    }
    %Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Entity{
      identifier: service,
      service_definition: test_service_one,
      status_details: test_service_one_status,
      instance_definitions: %{
        :"second@127.0.0.1" => Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Instance.Definition.new(service, :"second@127.0.0.1", %{min: 1, max: 3, target: 2}, 0.5)
      },
      instance_statuses: %{}, # pending
      health_report: Noizu.SimplePoolAdvanced.V3.ClusterManagement.HealthReport.new({:ref, Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Entity, service}),
      telemetry_handler: telemetry_handler,
      event_handler: event_handler,
    } |> Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Repo.create!(context)

    #-------------------------------------
    # test_service_three
    #-------------------------------------
    service = Noizu.SimplePoolAdvanced.Support.TestV3ThreePool
    test_service_three = Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Definition.new(service, %{min: 1, max: 3, target: 2}, %{min: 1, max: 3, target: 2})
    test_service_three_status = %Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Status{
      service: service,
      instances: %{
        :"first@127.0.0.1" => Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Instance.Status.new(service, :"first@127.0.0.1", nil, nil),
      },
      health_report: Noizu.SimplePoolAdvanced.V3.ClusterManagement.HealthReport.new({:ref, Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Entity, service}),
    }
    %Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Entity{
      identifier: service,
      service_definition: test_service_three,
      status_details: test_service_three_status,
      instance_definitions: %{
        :"first@127.0.0.1" => Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.Instance.Definition.new(service, :"first@127.0.0.1", %{min: 1, max: 3, target: 2}, 1.0),
      },
      instance_statuses: %{}, # pending
      health_report: Noizu.SimplePoolAdvanced.V3.ClusterManagement.HealthReport.new({:ref, Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Entity, service}),
      telemetry_handler: telemetry_handler,
      event_handler: event_handler,
    } |> Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Service.State.Repo.create!(context)

    #----------------------------------------------------------------
    # Node Manager Definitions
    #----------------------------------------------------------------
    cluster_node = :"first@127.0.0.1"
    %Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Node.State.Entity{
      identifier: cluster_node,
      node_definition: Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Node.Definition.new(cluster_node, %{low: 0, high: 1000, target: 500}, %{low: 0.0, high: 85.0, target: 70.0}, %{low: 0.0, high: 85.0, target: 70.0}, %{low: 0.0, high: 85.0, target: :none}, 1.0),
      status_details: Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Node.Status.new(cluster_node ),
      health_report: Noizu.SimplePoolAdvanced.V3.ClusterManagement.HealthReport.new({:ref, Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Node.State.Entity, cluster_node }),
    } |> Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Node.State.Repo.create!(context)

    cluster_node = :"second@127.0.0.1"
    %Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Node.State.Entity{
      identifier: cluster_node,
      node_definition: Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Node.Definition.new(cluster_node, %{low: 0, high: 1000, target: 500}, %{low: 0.0, high: 85.0, target: 70.0}, %{low: 0.0, high: 85.0, target: 70.0}, %{low: 0.0, high: 85.0, target: :none}, 1.0),
      status_details: Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Node.Status.new(cluster_node ),
      health_report: Noizu.SimplePoolAdvanced.V3.ClusterManagement.HealthReport.new({:ref, Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Node.State.Entity, cluster_node }),
    } |> Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Node.State.Repo.create!(context)

    #----------------------------------------------------------------
    # Populate Cluster Configuration
    #----------------------------------------------------------------
    service_definitions = %{
      Noizu.SimplePoolAdvanced.Support.TestV3Pool => test_service_one,
      Noizu.SimplePoolAdvanced.Support.TestV3TwoPool => test_service_two,
      Noizu.SimplePoolAdvanced.Support.TestV3ThreePool => test_service_three,
    }
    service_statuses = %{
      Noizu.SimplePoolAdvanced.Support.TestV3Pool => test_service_one_status,
      Noizu.SimplePoolAdvanced.Support.TestV3TwoPool => test_service_two_status,
      Noizu.SimplePoolAdvanced.Support.TestV3ThreePool => test_service_three_status,
    }
    %Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.State.Entity{
      identifier: :default_cluster,
      cluster_definition: Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Definition.new(:default_cluster),
      service_definitions: service_definitions,
      service_statuses: service_statuses,
      status_details: Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.Status.new(:default_cluster),
      health_report: Noizu.SimplePoolAdvanced.V3.ClusterManagement.HealthReport.new({:ref, Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.State.Entity, :default_cluster}),
      telemetry_handler: telemetry_handler,
      event_handler: event_handler,
    } |> Noizu.SimplePoolAdvanced.V3.ClusterManagement.Cluster.State.Repo.create!(context)

    :ok
  end




  def setup_first() do
    context = Noizu.ElixirCore.CallingContext.system(%{})

    #=================================================================
    # Cluster Manager
    #=================================================================
    telemetry_handler = nil
    event_handler = nil


    # Setup Cluster Configuration
    configure_test_cluster(context, telemetry_handler, event_handler)

    # Bring Cluster Online
    Noizu.SimplePoolAdvanced.V3.ClusterManagementFramework.ClusterManager.start(%{}, context)
    Noizu.SimplePoolAdvanced.V3.ClusterManagementFramework.ClusterManager.bring_cluster_online(%{}, context)


    # Bring Node (And Appropriate Services) Online - this will spawn actual Service Instances, ClusterManager will bring on service managers if not already online.
    Noizu.SimplePoolAdvanced.V3.ClusterManagementFramework.Cluster.NodeManager.start({:"first@127.0.0.1", %{}}, context)
    Noizu.SimplePoolAdvanced.V3.ClusterManagementFramework.Cluster.NodeManager.bring_node_online(:"first@127.0.0.1", %{}, context)

    # Wait for node to register online
    Noizu.SimplePoolAdvanced.V3.ClusterManagementFramework.Cluster.NodeManager.block_for_state(:"first@127.0.0.1", :online, context, 30_000)
    #Noizu.SimplePoolAdvanced.V3.ClusterManagementFramework.Cluster.NodeManager.block_for_state(:"second@127.0.0.1", :online, context, 30_000)
    case Noizu.SimplePoolAdvanced.V3.ClusterManagementFramework.Cluster.NodeManager.block_for_status(:"first@127.0.0.1", [:green, :degraded], context, 30_000) do
      {:ok, _s} ->
        Logger.info("""
        ================================================================
        !!! Test Cluster Services: :"first@126.0.0.1"  # {inspect s} !!!
        ================================================================
        """)

      e ->
      Logger.error("""
      ================================================================
      !!! Unable to bring system fully online: :"first@126.0.0.1" # {inspect e} !!!
      ================================================================
      """)
      e
    end


:ok

  end

  def setup_second() do

    Application.ensure_all_started(:semaphore)

    IO.puts """
    =============== SETUP SECOND TEST NODE =====================
    node: #{node()}
    semaphore_test: #{inspect :rpc.call(node(), Semaphore, :acquire, [:test, 5])}
    ============================================================
    """

    p = spawn fn ->

      Noizu.SimplePoolAdvanced.V3.Database.MonitoringFramework.DetailedServiceEvent.Table.create()
      Noizu.SimplePoolAdvanced.V3.Database.MonitoringFramework.DetailedServerEvent.Table.create()

      Noizu.SimplePoolAdvanced.V3.Database.MonitoringFramework.DetailedServiceEvent.Table.add_copy(node(), :memory)
      Noizu.SimplePoolAdvanced.V3.Database.MonitoringFramework.DetailedServerEvent.Table.add_copy(node(), :memory)

      :ok = Amnesia.Table.wait(Noizu.SimplePoolAdvanced.V3.Database.tables(), 5_000)

      context = Noizu.ElixirCore.CallingContext.system(%{})

      # Bring Node (And Appropriate Services) Online - this will spawn actual Service Instances, ClusterManager will bring on service managers if not already online.
      Noizu.SimplePoolAdvanced.V3.ClusterManagementFramework.Cluster.NodeManager.start({:"second@127.0.0.1", %{}}, context)
      Noizu.SimplePoolAdvanced.V3.ClusterManagementFramework.Cluster.NodeManager.bring_node_online(:"second@127.0.0.1", %{}, context)
      case Noizu.SimplePoolAdvanced.V3.ClusterManagementFramework.Cluster.NodeManager.block_for_status(:"second@127.0.0.1", [:green, :degraded], context, 30_000) do
        {:ok, _s} ->
          Logger.info("""
          ================================================================
          !!! Test Cluster Services:  # {inspect s} !!!
          ================================================================
          """)

        e ->
          Logger.error("""
          ================================================================
          !!! Unable to bring system fully online:  # {inspect e} !!!
          ================================================================
          """)
          e
      end


      receive do
        :halt -> IO.puts "halting process"
      end
    end
    {:pid, p}
  end
end
