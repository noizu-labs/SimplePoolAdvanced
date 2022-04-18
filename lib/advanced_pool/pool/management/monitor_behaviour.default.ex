#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.V3.MonitorBehaviour.Default do
  alias Noizu.ElixirCore.OptionSettings
  alias Noizu.ElixirCore.OptionValue
  alias Noizu.ElixirCore.OptionList
  require Logger

  # @todo alternative solution for specifying features.
  @features ([:auto_identifier, :lazy_load, :async_load, :inactivity_check, :s_redirect, :s_redirect_handle, :ref_lookup_cache, :call_forwarding, :graceful_stop, :crash_protection])
  @default_features ([:lazy_load, :s_redirect, :s_redirect_handle, :inactivity_check, :call_forwarding, :graceful_stop, :crash_protection])

  @default_timeout 15_000
  @default_shutdown_timeout 30_000
  def prepare_options_slim(options), do: Noizu.ElixirCore.SlimOptions.slim(prepare_options(options))
  def prepare_options(options) do
    settings = %OptionSettings{
      option_settings: %{
        features: %OptionList{option: :features, default: Application.get_env(:noizu_advanced_pool, :default_features, @default_features), valid_members: @features, membership_set: false},
        verbose: %OptionValue{option: :verbose, default: :auto},
        worker_state_entity: %OptionValue{option: :worker_state_entity, default: :auto},
        default_timeout: %OptionValue{option: :default_timeout, default:  Application.get_env(:noizu_advanced_pool, :default_timeout, @default_timeout)},
        shutdown_timeout: %OptionValue{option: :shutdown_timeout, default: Application.get_env(:noizu_advanced_pool, :default_shutdown_timeout, @default_shutdown_timeout)},
        default_definition: %OptionValue{option: :default_definition, default: :auto},
        log_timeouts: %OptionValue{option: :log_timeouts, default: Application.get_env(:noizu_advanced_pool, :default_log_timeouts, true)},
        max_supervisors: %OptionValue{option: :max_supervisors, default: Application.get_env(:noizu_advanced_pool, :default_max_supervisors, 100)},
      }
    }
    OptionSettings.expand(settings, options)
  end


  @temporary_core_events MapSet.new([:start, :shutdown])
  def core_events(_pool) do
    # TODO use fast global wrapper around SettingTable
    @temporary_core_events
  end

  def record_service_event!(pool, event, _details, context, _opts) do
    if MapSet.member?(core_events(pool), event) do
      Logger.info(fn() -> {"TODO - write to ServiceEventTable #{inspect event}", Noizu.ElixirCore.CallingContext.metadata(context)} end)
    else
      Logger.info(fn() -> {"TODO - write to DetailedServiceEventTable #{inspect event}", Noizu.ElixirCore.CallingContext.metadata(context)} end)
    end
  end
end
