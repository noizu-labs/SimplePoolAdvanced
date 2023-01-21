defmodule Noizu.AdvancedPool.DefaultSupervisor do
  use Supervisor
  def start_link(id, pool, context, options) do
    IO.puts "STARTING: #{inspect pool}"
    supervisor = pool.config()[:otp][:supervisor] || __MODULE__
    Supervisor.start_link(supervisor, {id, pool, context, options}, name: id)
  end
  
  def init({_id, pool, context, options}) do
    cond do
      pool.config()[:stand_alone] ->
        server = pool.__server__().server_spec(context, options)
        children = [
          server
        ]
        Supervisor.init(children, strategy: :one_for_one)
      :else ->
        server = pool.__server__().server_spec(context, options)
        children = [
          server
        ]
        Supervisor.init(children, strategy: :one_for_one) |> IO.inspect(label: "HMMMMMMMMMMMM")
    end
  end
  
  def pool_spec(pool, context, options \\ nil) do
    id = options[:id] || pool
    supervisor = pool.config()[:otp][:supervisor] || __MODULE__
    start_params = [id, pool, context, options]
    %{
      id: id,
      name: id,
      type: :supervisor,
      start: {supervisor, :start_link, start_params}
    } |> IO.inspect(label: :pool_spec)
  end
  
  def handle_call(msg, _from, state) do
    {:reply, {:uncaught, msg, state}, state}
  end
  def handle_cast(msg, state) do
    {:noreply, state}
  end
  def handle_info(msg, state) do
    {:noreply, state}
  end
  



end