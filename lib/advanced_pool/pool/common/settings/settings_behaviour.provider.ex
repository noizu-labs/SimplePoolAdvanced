#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.SettingsBehaviour.Default do
  require Logger

  def wait_for_condition(condition, timeout) do
    cond do
      timeout == :infinity -> wait_for_condition_inner(condition, timeout)
      is_integer(timeout) ->  wait_for_condition_inner(condition, :os.system_time(:millisecond) + timeout)
    end
  end

  def wait_for_condition_inner(condition, timeout) do
    case condition.() do
      true -> :ok
      :ok -> :ok
      {:ok, details} -> {:ok, details}
      e ->
        t =:os.system_time(:millisecond)
        if (t < timeout) do
          Process.sleep( min(max(50, div((timeout - t), 60)), 500))
          wait_for_condition_inner(condition, timeout)
        else
          {:timeout, e}
        end
    end
  end



  @doc """
  Return a banner string.
  ------------- Example -----------
  Multi-Line
  Banner
  ---------------------------------
  """
  def banner(header, msg) do
    header = cond do
               is_bitstring(header) -> header
               is_atom(header) -> "#{header}"
               true -> "#{inspect header}"
             end

    msg = cond do
            is_bitstring(msg) -> msg
            is_atom(msg) -> "#{msg}"
            true -> "#{inspect msg}"
          end

    header_len = String.length(header)
    len = 120

    sub_len = div(header_len, 2)
    rem = rem(header_len, 2)

    l_len = 59 - sub_len
    r_len = 59 - sub_len - rem

    char = "*"

    lines = String.split(msg, "\n", trim: true)

    top = "\n#{String.duplicate(char, l_len)} #{header} #{String.duplicate(char, r_len)}"
    bottom = String.duplicate(char, len) <> "\n"
    middle = for line <- lines do
               "#{char} " <> line
             end
    Enum.join([top] ++ middle ++ [bottom], "\n")
  end



  @doc """
  Return Meta Information for specified module.
  """
  def meta(module) do
    case FastGlobal.get(module.meta_key(), :no_entry) do
      :no_entry ->
        update = module.meta_init()
        module.meta(update)
        update
      v = %{} -> v
    end
  end

  @doc """
  Update Meta Information for module.
  """
  def meta(module, update) do
    if Semaphore.acquire({{:meta, :write}, module}, 1) do
      existing = case FastGlobal.get(module.meta_key(), :no_entry) do
                   :no_entry -> module.meta_init()
                   v -> v
                 end
      update = Map.merge(existing, update)
      FastGlobal.put(module.meta_key(), update)
      update
    else
      false
    end
  end


  @doc """
  Initial Meta Information for Module.
  """
  def meta_init(module, _arguments \\ %{}) do
    # Grab effective options
    options = module.options()

    # meta variables

    max_restarts = options[:max_restarts] || 1_000_000
    max_seconds = options[:max_seconds] || 1
    strategy = options[:strategy] || :one_for_one
    auto_load = Enum.member?(options[:features] || [], :auto_load)
    async_load = Enum.member?(options[:features] || [], :async_load)


    response = %{
      verbose: :pending,
      stand_alone: :pending,
      max_restarts: max_restarts,
      max_seconds: max_seconds,
      strategy: strategy,
      auto_load: auto_load,
      async_load: async_load,
      featuers: MapSet.new(options[:features] || [])
    }

    # Base vs. Inherited Specific
    if (module.pool() == module) do
      verbose = if (options[:verbose] == :auto), do: Application.get_env(:noizu_advanced_pool, :verbose, false), else: options[:verbose]
      stand_alone = module.stand_alone()
      %{response| verbose: verbose, stand_alone: stand_alone}
    else
      verbose = if (options[:verbose] == :auto), do: module.pool().verbose(), else: options[:verbose]
      stand_alone = module.pool().stand_alone()
      %{response| verbose: verbose, stand_alone: stand_alone}
    end
  end

  def pool_worker_state_entity(pool, :auto), do: Module.concat(pool, "WorkerState.Entity")
  def pool_worker_state_entity(_pool, worker_state_entity), do: worker_state_entity




  def profile_start(%{meta: _} = state, profile \\ :default) do
    state
    |> update_in([Access.key(:meta), :profiler], &(&1 || %{}))
    |> put_in([Access.key(:meta), :profiler, profile], %{start: :os.system_time(:millisecond)})
  end

  def profile_end(%{meta: _} = state, profile, prefix, options) do
    state = state
            |> update_in([Access.key(:meta), :profiler], &(&1 || %{}))
            |> update_in([Access.key(:meta), :profiler, profile], &(&1 || %{}))
            |> put_in([Access.key(:meta), :profiler, profile, :end], :os.system_time(:millisecond))



    interval = (state.meta.profiler[profile][:end]) - (state.meta.profiler[profile][:start] || 0)
    cond do
      state.meta.profiler[profile][:start] == nil -> Logger.warn(fn -> "[#{prefix} prof] profile_start not invoked for #{profile}" end)
      options[:error] && interval >= options[:error] ->
        options[:log] && Logger.error(fn -> "[#{prefix} prof] #{profile} exceeded #{options[:error]} milliseconds @#{interval}" end)
        _state = state
                 |> put_in([Access.key(:meta), :profiler, profile, :flag], :error)
      options[:warn] && interval >= options[:warn] ->
        options[:log] && Logger.warn(fn -> "[#{prefix} prof] #{profile} exceeded #{options[:warn]} milliseconds @#{interval}" end)
        _state = state
                 |> put_in([Access.key(:meta), :profiler, profile, :flag], :warn)
      options[:info] && interval >= options[:info] ->
        options[:log] && Logger.info(fn -> "[#{prefix} prof] #{profile} exceeded #{options[:info]} milliseconds @#{interval}" end)
        _state = state
                 |> put_in([Access.key(:meta), :profiler, profile, :flag], :info)
      :else ->
        _state = state
                 |> put_in([Access.key(:meta), :profiler, profile, :flag], :green)
    end
  end


  def expand_table(module, table, name) do
    # Apply Schema Naming Convention if not specified
    if (table == :auto) do
      path = Module.split(module)
      root_table = Application.get_env(:noizu_scaffolding, :default_database, Module.concat([List.first(path), "Database"]))
                   |> Module.split()
      inner_path = Enum.slice(path, 1..-1)
      Module.concat(root_table ++ inner_path ++ [name])
    else
      table
    end
  end
end
