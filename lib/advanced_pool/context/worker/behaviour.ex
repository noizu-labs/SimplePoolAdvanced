defmodule Noizu.AdvancedPool.Worker.Behaviour do
  @moduledoc """
  Defines the behavior (callbacks) and common operations for workers within `Noizu.AdvancedPool`.
  This module standardizes the expected functionalities that a pool worker should implement, including
  initialization, state management, message handling, and lifecycle events such as reloading, fetching,
  pinging, and termination.

  `Worker.Behaviour` provides a set of callbacks that serve as a contract for worker implementation.
  It ensures consistency across different worker types and simplifies the process of integrating new
  worker modules into the pool by specifying clear expectations on how they should behave and be interacted with.

  Using this behavior module streamlines the development of scalable and maintainable pool workers,
  as it abstracts the common worker behavior patterns and allows developers to focus on worker-specific logic.
  """

  @type worker :: any
  @type info :: atom | term

  @type state :: Noizu.AdvancedPool.Worker.State.t
  @type context :: term
  @type options :: term | Map.t | nil
  
  @type response_tuple :: {:ok, term} | {:error, term}
  @type response_struct(type) :: {:ok, type} | {:error, term}
  
  @type noreply_response :: {:noreply, state} | {:noreply, state, term}
  @type reply_response(response) :: {:reply, response, state} | {:reply, response, state, term}
  @type worker_identifier :: term
  @type ref :: {:ref, module, term} | worker_identifier
  
  
  @callback __pool__() :: module
  @callback __dispatcher__() :: module
  @callback __registry__() :: module

  @callback recipient(term) :: response_tuple()

  @callback init(ref, term, term) :: state()
  @callback load(state, context, options) :: response_struct(state)
  @callback reload!(state, context, options) :: reply_response(state | any)
  
  @callback fetch(state, value :: term, context) :: reply_response(any)
  @callback ping(state,  context) :: reply_response({:pong, pid})
  @callback kill!(state, context, options) :: noreply_response()
  @callback crash!(state, context, options) :: noreply_response()
  @callback hibernate(state, context, options) :: noreply_response()
  @callback persist!(state, context, options) :: reply_response({:ok, state} | {:ok, term} | {:error, term})

  @doc """
  Defines common behaviors for pool workers using a `__using__` macro, allowing customization of the worker module.
  By embedding this macro within a worker module, default behaviors for the callbacks are provided, which can be
  overridden as necessary for the specific requirements of the worker. It also binds default operations like
  `init`, `load`, `reload!`, `fetch`, etc., to their implementations, simplifying the worker module's implementation.
  """
  defmacro __using__(options) do
    pool = options[:pool] || (Module.split(__CALLER__.module) |> Enum.slice(0..-2) |> Module.concat())
    quote bind_quoted: [pool: pool] do
      @behaviour Noizu.AdvancedPool.Worker.Behaviour
      #@behaviour Noizu.ERP.Behaviour
      require Noizu.AdvancedPool.Message
      alias Noizu.AdvancedPool.Message, as: M

      @pool pool

      @doc """
      Returns the pool module associated with this worker, which is determined based on the worker module's structure.
      Access to the pool module is often required for fetching global state or configurations.

      The `__pool__/0` function plays a critical role in facilitating access to the wider context in which the worker operates.
      """
      def __pool__(), do: @pool

      @doc """
      Retrieves the dispatcher module for the current pool which the worker is a part of. The dispatcher is responsible
      for message routing, ensuring that messages are delivered to this worker server process correctly.
      """
      def __dispatcher__(), do: apply(__pool__(), :__dispatcher__, [])

      @doc """
      Fetches the registry module associated with the current pool. The registry tracks all active processes within the
      pool, facilitating process lookups and communication.
      """
      def __registry__(), do: apply(__pool__(), :__registry__, [])

      @doc """
      Creates and validates a recipient link for a worker within the pool. This link is essential for establishing
      direct communication channels with the worker.
      """
      def recipient(M.link(recipient: M.ref(module: __MODULE__)) = link ), do: {:ok, link}
      def recipient(ref), do: ref_ok(ref)


      @doc """
      Initializes the worker process with a unique identifier and other relevant startup arguments,
      setting up the worker's foundational state.
      """
      def init({:ref, __MODULE__, identifier}, args, context) do
        %__MODULE__{
          identifier: identifier
        }
      end

      @doc """
      Sets the status of the worker's state to `:loaded`, indicating the process is ready to handle tasks.
      This is typically part of the worker initialization lifecycle.
      """
      def load(%Noizu.AdvancedPool.Worker.State{} = state, context, options \\ nil) do
        {:ok, %Noizu.AdvancedPool.Worker.State{state| status: :loaded}}
      end

      @doc """
      Attempts to reload the worker's internal state, providing an opportunity to refresh its configuration
      or state without restarting the process.
      """
      def reload!(%Noizu.AdvancedPool.Worker.State{} = state, context, options \\ nil) do
        with {:ok, state} <- load(state, context, options) do
          {:noreply, state}
        else
          _ -> {:noreply, state}
        end
      end



      @doc """
      Retrieves the process or other information for the worker process.
      """
      def fetch(%Noizu.AdvancedPool.Worker.State{} = state, :state, _) do
        {:reply, state, state}
      end
      def fetch(%Noizu.AdvancedPool.Worker.State{} = state, :process, _) do
        {:reply, {state.identifier, node(), self()}, state}
      end



      @doc """
      Sends a 'ping' to the worker process to check its responsiveness. Replies with a `:pong` message if
      the worker is active and responsive.
      """
      def ping(state, _, _ \\ nil) do
        {:reply, :pong, state}
      end



      @doc """
      Instructs the worker process to gracefully shut down, ending its operations and terminating its state.
      """
      def kill!(state, _, _ \\ nil) do
        {:stop, :shutdown, :ok, state}
      end


      @doc """
      Triggers an artificial crash within the worker process for testing purposes or to simulate failure scenarios.
      """
      def crash!(state, _, _ \\ nil) do
        throw "User Initiated Crash"
      end


      @doc """
      Places the worker process in a hibernation state to conserve system resources, reducing its memory footprint
      until the next message is received.
      """
      def hibernate(state, _, _ \\ nil) do
        {:reply, :ok, state, :hibernate}
      end


      @doc """
      Attempts to persist the worker's internal state. In the default behavior, this functionality is not supported,
      providing a response indicating so.
      """
      def persist!(state, _, _ \\ nil) do
        {:reply, :not_supported, state}
      end
      
      #-----------------------
      #
      #-----------------------

      @doc """
      Handles direct synchronous calls to the worker process, matching against specific commands like `reload!`,
      `fetch`, `ping`, `kill!`, `crash!`, `hibernate`, and `persist!`, invoking corresponding actions on the worker's state.
      If a message does not match any specified commands, it is marked as unhandled.
      """
      def handle_call(M.s(call: {:reload!, options}, context: context), _, state) do
        reload!(state, context, options)
      end
      def handle_call(M.s(call: {:fetch, type}, context: context), _, state) do
        fetch(state, type, context)
      end
      def handle_call(M.s(call: :ping, context: context, options: options), _, state) do
        ping(state, context, options)
      end
      def handle_call(M.s(call: :kill!, context: context, options: options), _, state) do
        kill!(state, context, options)
      end
      def handle_call(M.s(call: :crash!, context: context, options: options), _, state) do
        crash!(state, context, options)
      end
      def handle_call(M.s(call: :hibernate, context: context, options: options), _, state) do
        hibernate(state, context, options)
      end
      def handle_call(M.s(call: :persist!, context: context, options: options), _, state) do
        persist!(state, context, options)
      end
      def handle_call(msg, _, state) do
        {:reply, {:unhandled, msg}, state}
      end



      @doc """
      Responds to asynchronous cast messages sent to the worker, where the messages do not require a response.
      The default behavior does not handle the cast message but provides an acknowledgment through `:noreply`,
      indicating the continuation of the worker's process.
      """
      def handle_cast(_, state) do
        {:noreply, state}
      end

      @doc """
      Deals with all other messages that are not part of a synchronous call or asynchronous cast, using a default
      pattern that acknowledges the message without taking any specific action, thus maintaining the worker's state.
      """
      def handle_info(_, state) do
        {:noreply, state}
      end
      
      defoverridable [
        __pool__: 0,
        __dispatcher__: 0,
        __registry__: 0,
        recipient: 1,
        init: 3,
        load: 2,
        load: 3,
        reload!: 2,
        reload!: 3,
        fetch: 3,
        ping: 2,
        ping: 3,
        kill!: 2,
        kill!: 3,
        crash!: 2,
        crash!: 3,
        hibernate: 2,
        hibernate: 3,
        persist!: 2,
        persist!: 3,
        handle_call: 3,
        handle_cast: 2,
        handle_info: 2,
      ]
      
    end
  end
  
#  @callback status(worker) :: term
#  @callback status_details(worker) :: term
#  @callback migrate(worker, node, context, options) :: term


end
