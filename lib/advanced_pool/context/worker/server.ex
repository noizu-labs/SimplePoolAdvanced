defmodule Noizu.AdvancedPool.Worker.Server do
  use GenServer
  require Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M
  
  def start_link(ref = M.ref(module: m, identifier: id), args, context) do
    #IO.puts "STARTING: #{inspect m}"
    pool = apply(m, :__pool__, [])
    mod = pool.config()[:otp][:worker_server] || __MODULE__
    GenServer.start_link(mod, {ref, args, context})
    # |> IO.inspect(label: "#{pool}.worker.server start_link")
  end
  
  def init({ref = M.ref(module: worker, identifier: _), args, context}) do
    init_worker = apply(worker, :init, [ref, args, context])
    pool = apply(worker, :__pool__, [])
    registry = apply(pool, :__registry__, [])
    :syn.register(registry, {:worker, ref}, self(), [])
    #IO.puts "REGISTER: #{inspect registry} - #{inspect {:worker, ref}}"
    
    state = %Noizu.AdvancedPool.Worker.State{
      identifier: ref,
      handler: worker,
      status: :init,
      status_info: nil,
      worker: init_worker,
    }
    {:ok, state}
  end
  
  def spec(ref, args, context, options \\ nil) do
    gen_server = options[:server] || Noizu.AdvancedPool.Worker.Server
    %{
      id: ref,
      type: :worker,
      start: {gen_server, :start_link, [ref, [args], context]}
    }
  end

  def handle_call(msg, from, state) do
    apply(state.handler, :handle_call, [msg, from, state])
  end
  def handle_cast(msg, state) do
    apply(state.handler, :handle_cast, [msg, state])
  end
  def handle_info(msg, state) do
    apply(state.handler, :handle_info, [msg, state])
  end
  
end