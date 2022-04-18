#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.PoolBehaviour.Default do
  @moduledoc """
    Default Method Implementations for PoolBehaviour
  """
  alias Noizu.ElixirCore.OptionSettings
  alias Noizu.ElixirCore.OptionValue
  alias Noizu.ElixirCore.OptionList
  require Logger


  #---------------------------
  # Pool Option Parsing
  #-----------------------------------
  @features ([:auto_load, :auto_identifier, :lazy_load, :async_load, :inactivity_check, :s_redirect, :s_redirect_handle, :ref_lookup_cache, :call_forwarding, :graceful_stop, :crash_protection, :migrate_shutdown])
  @default_features ([:auto_load, :lazy_load, :s_redirect, :s_redirect_handle, :inactivity_check, :call_forwarding, :graceful_stop, :crash_protection, :migrate_shutdown])

  @modules ([:worker, :server, :worker_supervisor, :pool_supervisor, :monitor, :record_keeper])
  @default_modules ([])

  @default_worker_options ([])
  @default_server_options ([])
  @default_worker_supervisor_options ([])
  @default_pool_supervisor_options ([])
  @default_monitor_options ([])
  @default_record_keeper_options ([])
  @default_registry_options ([partitions: 256, keys: :unique])

  #---------
  # prepare_options_slim/1
  #---------
  def prepare_options_slim(options), do: Noizu.ElixirCore.SlimOptions.slim(prepare_options(options))

  #---------
  # prepare_options/1
  #---------
  def prepare_options(options) do
    settings = %OptionSettings{
      option_settings: %{
        features: %OptionList{option: :features, default: Application.get_env(:noizu_advanced_pool, :default_features, @default_features), valid_members: @features, membership_set: false},
        default_modules: %OptionList{option: :default_modules, default: Application.get_env(:noizu_advanced_pool, :default_modules, @default_modules), valid_members: @modules, membership_set: true},
        verbose: %OptionValue{option: :verbose, default: Application.get_env(:noizu_advanced_pool, :verbose, false)},

        service_manager: %OptionValue{option: :service_manager, default: Noizu.AdvancedPool.V3.ClusterManagementFramework.Cluster.ServiceManager},
        node_manager: %OptionValue{option: :node_manager, default: Noizu.AdvancedPool.V3.ClusterManagementFramework.Cluster.NodeManager},

        dispatch_table: %OptionValue{option: :dispatch_table, default: :auto},
        #dispatch_monitor_table: %OptionValue{option: :dispatch_monitor_table, default: :auto},
        registry_options: %OptionValue{option: :registry_options, default: Application.get_env(:noizu_advanced_pool, :default_registry_options, @default_registry_options)},

        record_keeper_options: %OptionValue{option: :record_keeper_options, default: Application.get_env(:noizu_advanced_pool, :default_record_keeper_options, @default_record_keeper_options)},
        monitor_options: %OptionValue{option: :monitor_options, default: Application.get_env(:noizu_advanced_pool, :default_monitor_options, @default_monitor_options)},
        worker_options: %OptionValue{option: :worker_options, default: Application.get_env(:noizu_advanced_pool, :default_worker_options, @default_worker_options)},
        server_options: %OptionValue{option: :server_options, default: Application.get_env(:noizu_advanced_pool, :default_server_options, @default_server_options)},
        worker_supervisor_options: %OptionValue{option: :worker_supervisor_options, default: Application.get_env(:noizu_advanced_pool, :default_worker_supervisor_options, @default_worker_supervisor_options)},
        pool_supervisor_options: %OptionValue{option: :pool_supervisor_options, default: Application.get_env(:noizu_advanced_pool, :default_pool_supervisor_options, @default_pool_supervisor_options)},
        worker_state_entity: %OptionValue{option: :worker_state_entity, default: :auto},
        max_supervisors: %OptionValue{option: :max_supervisors, default: Application.get_env(:noizu_advanced_pool, :default_max_supervisors, 100)},
      }
    }

    # Copy verbose, features, and worker_state_entity into nested module option lists.
    initial = OptionSettings.expand(settings, options)
    modifications = Map.take(initial.effective_options, [:worker_options, :server_options, :worker_supervisor_options, :pool_supervisor_options])
                    |> Enum.reduce(%{},
                         fn({k,v},acc) ->
                           v = v
                               |> Keyword.put_new(:verbose, initial.effective_options.verbose)
                               |> Keyword.put_new(:features, initial.effective_options.features)
                               |> Keyword.put_new(:worker_state_entity, initial.effective_options.worker_state_entity)
                           Map.put(acc, k, v)
                         end)
    %OptionSettings{initial| effective_options: Map.merge(initial.effective_options, modifications)}
  end
end