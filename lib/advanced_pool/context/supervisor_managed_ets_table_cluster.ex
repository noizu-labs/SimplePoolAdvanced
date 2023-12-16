defmodule Noizu.AdvancedPool.SupervisorManagedEtsTableCluster do
  require Logger
  use GenServer
  @default_settings [:public, :named_table, :set, read_concurrency: true]
  def child_spec(tables) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [tables]},
      type: :worker,
      restart: :permanent
    }
  end

  # Function to start the GenServer
  def start_link(tables) do
    GenServer.start_link(__MODULE__, {tables})
  end

  # Function to initialize all ETS tables and monitor them
  def init({tables}) do
    table_refs = Enum.map(tables,
      fn
        {table_name, settings} -> {table_name, start_and_monitor_table(table_name, settings)}
        table_name when is_atom(table_name) -> {table_name, start_and_monitor_table(table_name,  nil)}
      end)

    {:ok, Map.new(table_refs)}
  end

  # Function to start an ETS table and monitor it
  def start_and_monitor_table(table_name, options) do
    settings = options[:settings] || @default_settings

    :ets.new(table_name, settings)
    ref = :ets.whereis(table_name)

    if init = options[:init] do
      apply(init, [])
    end

    {table_name, ref}
  end

  # Handle DOWN messages for monitored ETS tables
  def handle_info(info, state) do
    Logger.warning("#{__MODULE__}.handle_info(#{inspect info}, #{inspect state})")
    {:noreply, state}
  end

  def handle_call({:get_and_update, mutator}, _from, state) do
    {reply, state} = apply(mutator, state)
    {:reply, reply, state}
  end

  def handle_call({:get, mutator}, _from, state) do
    reply = apply(mutator, state)
    {:reply, reply, state}
  end

  def handle_cast({:update, mutator}, state) do
    state = apply(mutator, state)
    {:noreply, state}
  end

  # Other necessary functions (handle_call, handle_cast, etc.) go here
end
