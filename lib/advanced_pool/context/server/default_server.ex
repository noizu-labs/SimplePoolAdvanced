defmodule Noizu.AdvancedPool.Server.DefaultServer do
  @moduledoc """
  Provides a default server implementation for the `Noizu.AdvancedPool` framework.
  `DefaultServer` is a `GenServer` that serves as a template for managing interactions with pool workers.
  It includes basic server functionalities such as initialization, message handling, and dynamic configuration
  based on predefined settings. This server can be customized and extended to fit specific requirements.

  The `DefaultServer` aims to simplify the management of pooled worker processes by acting as a message routing
  point, responding to requests, and performing actions on behalf of worker processes or clients requesting pool services.
  """

  use GenServer
  require Noizu.AdvancedPool.Message
  require Logger
  def start_link(id, server, context, options) do
    # IO.puts "STARTING: #{inspect server}"
    mod = server.config()[:otp][:server] || __MODULE__
    Logger.warning("""
    INIT #{__MODULE__}.#{inspect __ENV__.function}
    ***************************************
    #{inspect({id, server, context, options})}
    #{inspect mod}

    """)

    GenServer.start_link(mod, {id, server, context, options}, name: id)
    |> IO.inspect(label: "#{server}.server start_link")
  end


  @doc """
  Initializes the server with a predefined initial state. This function sets up the necessary state for the server process
  after being spawned. It accepts identifiers and options to customize its launch within the pool.

  The `init/1` function is fundamental in setting the groundwork for the server's operations within the worker pool
  by specifying its initial state and behavior.
  """
  def init({id, pool, context, options}) do
    Logger.warning("""
    INIT #{__MODULE__}.#{inspect __ENV__.function}
    ***************************************
    #{inspect({id, pool, context, options})}

    """)
    {:ok, :server_initial_state}
    |> IO.inspect(label: "Default Server Init")
  end


  @doc """
  Assembles the start specification for this server, based on configuration provided by the referenced server module,
  context and optional additional parameters. It forms the payload for the `Supervisor.start_link/3` function that kicks off the server process.

  The `server_spec/2-3` function streamlines the server spawning process, offering a uniform and reusable
  approach to defining server initialization parameters essential for the supervisory process within the pool.
  """
  def server_spec(server, context, options \\ nil) do
    id = options[:id] || server
    worker = server.config()[:otp][:server] || __MODULE__
    start_params = [id, server, context, options]
    %{
      id: id,
      type: :worker,
      start: {worker, :start_link, start_params}
    }
  end




  @doc """
  Provides a catch-all for synchronous `call` messages that are not otherwise matched by more specific clauses. It replies with an
  `uncaught` indicator, allowing for the identification of messages that require additional handling implementation.

  The existence of this function ensures a fallback for messages that have not met customized conditions, preventing unforeseen
  messages from causing unhandled exceptions within the server process.
  """
  def handle_call(Noizu.AdvancedPool.Message.msg_envelope(msg: {:s, :hello, context}), _, state) do
    {:reply, :world, state}
  end
  def handle_call(msg, _from, state) do
    {:reply, {:uncaught, msg, state}, state}
  end


  @doc """
  Offers a generic response mechanism for asynchronous `cast` messages, no matter the content. Since casts do not expect a return,
  this implementation signifies an unhandled message, albeit using a reply within the `GenServer`'s API for illustrative purposes.

  This function, usually accompanied by a `:noreply` response in typical implementations, reinforces the requirement for specific handling
  patterns for different types of messages.
  """
  def handle_cast(msg, state) do
    {:reply, {:uncaught, msg, state}, state}
  end


  @doc """
  Responds to unsolicited informational messages (`info`) received by the process. The default implementation signals that the message
  was not specifically caught by any handling pattern, suggesting that further handling logic might be required.

  The `handle_info/2` method acts as a blueprint for processing arbitrary messages that are not direct calls or casts, highlighting the
  need for robust message management within the server.
  """
  def handle_info(msg, state) do
    {:reply, {:uncaught, msg, state}, state}
  end

  def terminate(reason, state) do
    Logger.warning("""
    TERMINATE #{__MODULE__}#{inspect __ENV__.function}
    ***************************************
    #{inspect({reason, state})}
    """)
    :ok
  end

end
