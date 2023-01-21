defmodule Noizu.AdvancedPool.DefaultSupervisor do
  use Supervisor
  def start_link(id, pool, context, options) do
    supervisor = apply(pool, :config, [])[:otp][:supervisor] || __MODULE__
    Supervisor.start_link(supervisor, {id, pool, context, options}, name: id)
  end
  
  def init({_id, pool, context, options}) do
    cond do
      apply(pool, :config, [])[:stand_alone] ->
        [
          apply(pool, :__server__, []) |> apply(:server_spec, [context, options])
        ]
      :else ->
        [
          apply(pool, :__server__, []) |> apply(:server_spec, [context, options]),
          Registry.child_spec(keys: :unique, name: apply(pool, :__registry__, []),  partitions: 256)
        ]
    end
    |> Supervisor.init(strategy: :one_for_one)
  end
  
  def pool_spec(pool, context, options \\ nil) do
    id = options[:id] || pool
    supervisor = apply(pool, :config, [])[:otp][:supervisor] || __MODULE__
    start_params = [id, pool, context, options]
    %{
      id: id,
      name: id,
      type: :supervisor,
      start: {supervisor, :start_link, start_params}
    }
  end
  
end