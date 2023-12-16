defmodule Noizu.AdvancedPool.Worker.Server do
  @moduledoc """
  Represents the server component within `Noizu.AdvancedPool` worker processes, providing a `GenServer`
  implementation to manage state and handle messages for individual workers. The `Worker.Server` module is
  instrumental in facilitating communication between the pool and workers, managing initialization,
  registration, and message passing.

  This server module abstracts the complexities of worker management, enabling them to function in a
  supervised environment where they can be monitored, restarted, or replaced as necessary to maintain
  the pool's performance and reliability.
  """

  use GenServer
  require Logger
  require Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M
  
  def start_link(ref = M.ref(module: m, identifier: id), args, context) do

    pool = apply(m, :__pool__, [])
    mod = pool.config()[:otp][:worker_server] || __MODULE__

    Logger.info("""
    INIT #{__MODULE__}.#{inspect __ENV__.function}
    ***************************************

      #{inspect {pool, mod}}

    """)

    #IO.puts "STARTING: #{inspect m}"

    GenServer.start_link(mod, {ref, args, context})
    # |> IO.inspect(label: "#{pool}.worker.server start_link")
  end
  def terminate(reason, state) do
    Logger.info("""
    TERMINATE #{__MODULE__}#{inspect __ENV__.function}
    ***************************************
    #{inspect({reason, state})}
    """)
    :ok
  end

  @doc """
  Initializes the worker's server process with its unique reference, arguments, and context.
  During the initialization, it registers the new process with the pool's dispatcher, ensuring the correct
  routing of messages to this worker. It also constructs and sets the initial state of the worker, including
  its status and any other necessary information.

  The `init/1` function is key for bootstrapping worker processes, linking them with the broader pool's
  infrastructure and preparing them to commence their designated tasks.
  """
  def init({ref = M.ref(module: worker, identifier: _), args, context}) do
    init_worker = apply(worker, :init, [ref, args, context])
    pool = apply(worker, :__pool__, [])
    #registry = apply(pool, :__registry__, [])
    dispatcher = apply(pool, :__dispatcher__, [])
    apply(dispatcher, :__register__, [pool, ref, self(), [node: node()]])

    state = %Noizu.AdvancedPool.Worker.State{
      identifier: ref,
      handler: worker,
      status: :init,
      status_info: nil,
      worker: init_worker,
    }
    {:ok, state}
  end


  @doc """
  Generates a child specification used by the supervisor to start a server process for a worker.
  This spec includes the reference to the worker, its arguments, and the context necessary for initialization
  alongside any additional options provided.

  The `spec/3-4` function plays a pivotal role in the dynamic instantiation of worker servers, outlining how they
  should be brought into existence within the pool's supervision hierarchy.
  """
  def spec(ref, args, context, options \\ nil) do
    gen_server = options[:server] || Noizu.AdvancedPool.Worker.Server
    %{
      id: ref,
      type: :worker,
      start: {gen_server, :start_link, [ref, [args], context]}
    }
  end


  @doc """
  Delegates the handling of synchronous call messages to the appropriate function within the worker module.
  It extracts the worker handler from the state and invokes its `handle_call` function, forwarding the message
  contents, the sender, and the current state for processing.

  This `handle_call/3` implementation allows for highly customizable worker behavior while maintaining the
  benefits of a standardized server interface.
  """
  def handle_call(msg, from, state) do
    apply(state.handler, :handle_call, [msg, from, state])
  end


  @doc """
  Dispatches the handling of asynchronous cast messages to the worker's handler. It identifies the relevant
  function within the worker module and applies the `handle_cast` function, passing along the message and
  current worker state.

  The `handle_cast/2` function ensures that workers process cast messages in accordance with their defined behavior,
  continuing the server's role as an intermediary that efficiently relays communication without imposing additional logic.
  """
  def handle_cast(msg, state) do
    apply(state.handler, :handle_cast, [msg, state])
  end


  @doc """
  Relays any other messages received by the server to the worker's `handle_info` function. It employs the worker
  module's designated info handler to take appropriate action based on the unsolicited messages and state provided.

  This handling pattern via `handle_info/2` facilitates responsiveness to non-standard messages, crucial for timers,
  monitoring, or other system events that require attention outside the typical call and cast flow.
  """
  def handle_info(msg, state) do
    apply(state.handler, :handle_info, [msg, state])
  end
  
end
