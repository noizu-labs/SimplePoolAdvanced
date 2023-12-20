defmodule Noizu.AdvancedPool.Message.Dispatch do
  @moduledoc """
  Provides the message dispatching functionalities for the Noizu.AdvancedPool system.

  The `Noizu.AdvancedPool.Message.Dispatch` module is responsible for delivering messages to pool workers and servers in a reliable and consistent manner. It abstracts the complexity of asynchronous and synchronous calls, casting, and task management involved in effective message routing within the advanced pool architecture.

  Features include:
    - Synchronous and asynchronous message dispatching to workers.
    - Dynamic spawning of recipient processes if they do not exist.
    - Safe message dispatching with error and exit handling.
    - Timeout handling for message response waits.
    - Task-based dispatching for long-running operations.
    - Reference validation and recipient resolution.
    - Integration with various types of recipients: workers, servers, and monitoring processes.

  All message dispatch functions (`s_call`, `s_call!`, `s_cast`, `s_cast!`) wrap the given message in an envelope with appropriate metadata and use the underlying dispatching mechanisms to handle delivery to the target processes, providing a uniform and flexible interface for message routing in the pool system.

  The `__dispatch__` function series implement the internal logic and decision-making process for how the messages should be routed, utilizing the GenServer `call` and `cast` functions as per the message type.

  The handling of tasks, timeouts, and safety options are driven by the settings provided with each message, allowing customization of the dispatch behavior based on specific use-case requirements.

  This module is central to ensuring the communication in the advanced pool remains robust, responsive, and adaptable to various operational scenarios.
  """
  require Logger
  require Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M

  @doc """
  Sends a synchronous call message to the specified recipient, expecting a response.

  This function allows processes to make blocking, synchronous calls to workers or servers, which must complete before continuing execution. It ensures the recipient receives the message and provides a response.

  ## Examples

      # Synchronous call without options or default timeout
      Noizu.AdvancedPool.Message.Dispatch.s_call(ref, :some_call, call_context)

      # Synchronous call with options and a custom timeout
      Noizu.AdvancedPool.Message.Dispatch.s_call(ref, :some_call, call_context, options, 10_000)

  """
  def s_call(ref, call, context, options \\ nil,timeout \\ :default) do
      with {:ok, pool} <- recipient_pool(ref) do
        identifier = {self(), :os.system_time(:millisecond)}
        settings = apply(pool, :__call_settings__, [])
        timeout = cond do
                    timeout == :default -> M.settings(settings, :timeout)
                    :else -> timeout
                  end
        M.msg_envelope(
          identifier: identifier,
          type: :call,
          settings: M.settings(settings, spawn?: false, timeout: timeout),
          recipient: ref,
          msg: M.s(call: call, context: context, options: options)
        ) |> __dispatch__()
      end
  end

  @doc """
  Sends a synchronous call message similar to `s_call/4-5`, but it ensures the recipient is spawned if not already present.

  Offers stronger guarantees for message delivery and receipt by ensuring the target process exists. This is especially useful when the state of the recipient process is uncertain or dynamically managed.

  ## Examples

      # Synchronous call ensuring recipient is spawned
      Noizu.AdvancedPool.Message.Dispatch.s_call!(ref, :some_call, call_context)

  """
  def s_call!(ref, call, context, options \\ nil, timeout \\ :default) do
    with {:ok, pool} <- recipient_pool(ref) do
      identifier = {self(), :os.system_time(:millisecond)}
      settings = apply(pool, :__call_settings__, [])
      timeout = cond do
                  timeout == :default -> M.settings(settings, :timeout)
                  :else -> timeout
                end
      M.msg_envelope(
        identifier: identifier,
        type: :call,
        settings: M.settings(settings, spawn?: true, timeout: timeout),
        recipient: ref,
        msg: M.s(call: call, context: context, options: options)
      ) |> __dispatch__()
    end
  end

  @doc """
  Sends an asynchronous cast message to the recipient, not expecting a response.

  Useful for notifications or commands where an immediate response is not needed. Optimizes throughput by allowing the sender to continue without waiting.

  ## Examples

      # Asynchronous cast without options or default timeout
      Noizu.AdvancedPool.Message.Dispatch.s_cast(ref, :some_cast, call_context)

  """
  def s_cast(ref, call, context, options \\ nil, timeout \\ :default) do
    with {:ok, pool} <- recipient_pool(ref) do
      identifier = {self(), :os.system_time(:millisecond)}
      settings = apply(pool, :__cast_settings__, [])
      timeout = cond do
                  timeout == :default -> M.settings(settings, :timeout)
                  :else -> timeout
                end
      M.msg_envelope(
        identifier: identifier,
        type: :cast,
        settings: M.settings(settings, spawn?: false, timeout: timeout),
        recipient: ref,
        msg: M.s(call: call, context: context, options: options)
      ) |> __dispatch__()
    end
  end

  @doc """
  Sends an asynchronous cast message to the recipient, like `s_cast/4-5`, but can spawn the recipient if it doesn't exist.

  Ensures the message delivery by spawning the recipient process dynamically if necessary. This offers more robust message handling when the recipient's existence is managed on-demand.

  ## Examples

      # Asynchronous cast ensuring recipient is spawned
      Noizu.AdvancedPool.Message.Dispatch.s_cast!(ref, :some_cast, call_context)

  """
  def s_cast!(ref, call, context, options \\ nil, timeout \\ :default) do
    with {:ok, pool} <- recipient_pool(ref) do
      identifier = {self(), :os.system_time(:millisecond)}
      settings = apply(pool, :__cast_settings__, [])
      timeout = cond do
                  timeout == :default -> M.settings(settings, :timeout)
                  :else -> timeout
                end
      M.msg_envelope(
        identifier: identifier,
        type: :cast,
        settings: M.settings(settings, spawn?: true, timeout: timeout),
        recipient: ref,
        msg: M.s(call: call, context: context, options: options)
      ) |> __dispatch__()
    end
  end

  # __dispatch__/1
  #--------------------------------
  # Dispatches a message envelope, deciding whether to execute synchronously or asynchronously as a task,
  # based on the envelope's settings.
  #
  # Centralizes the message dispatching logic, making the decision on the execution context—synchronous
  # or using Elixir tasks for asynchronous operations.
  #
  # It delegates to `__dispatch__inner` for the actual message delivery logic, while managing task creation if specified by settings.
  defp __dispatch__(M.msg_envelope(identifier: _, settings: settings) = message) do
    case as_task(settings) do
      false -> __dispatch__inner(message)
      nil -> __dispatch__inner(message)
      true -> Task.async(__MODULE__, :__dispatch__inner, [message])
      task_supervisor ->
        Task.Supervisor.async_nolink(task_supervisor, __MODULE__, :__dispatch__inner, [message])
    end
  end

  # __dispatch__inner/1
  #--------------------------------
  #  Provides a safe dispatching mechanism that wraps the lower-level message dispatch logic.
  #
  #  If an error or exit occurs during message dispatching, the function ensures that the dispatcher
  #  does not crash by catching such exceptions.
  #
  #  This method contributes to the robustness of the dispatch system by guarding against
  #  unexpected runtime issues.
  defp __dispatch__inner(M.msg_envelope(settings: settings) = message) do
    cond do
      safe_call(settings) ->
        try do
          __dispatch__inner__do(message)
        rescue e -> {:error, e}
        catch
          :exit, e -> {:error, {:exit, e}}
          e -> {:error, e}
        end
      :else ->
        __dispatch__inner__do(message)
    end
  end

  # __dispatch__inner__do/1
  #--------------------------------
  #  Delivers a message based on its type (`:cast` or `:call`) to the intended recipient,
  #  handling the GenServer functions as necessary.
  #
  #  Abstracts the intricacies of message dispatch by resolving the appropriate recipient
  #  and invoking GenServer's `cast` or `call`, depending on the message type.
  #
  #  It uses the `recipient_register` function to find the correct recipient and sends the message accordingly.
  defp __dispatch__inner__do(M.msg_envelope(type: :cast, recipient: recipient, settings: settings) = message) do
    case recipient_register(recipient) do
      {:dynamic, dispatcher, terms} ->
        apply(dispatcher, :__process__, [message| (terms || [])])
      {:ok, handle} -> {:ok, handle}
      M.link(process: pid) -> {:ok, pid}
      error -> error
    end
    |> case do
         {:dispatch, _dispatcher, :waiting, task} ->
           with {:ok, {:ok, handle}} <- Task.yield(task, timeout(settings)) do
             GenServer.cast(handle, message)
           end
         {:ok, handle} -> GenServer.cast(handle, message)
         error -> error
       end
  end

  defp __dispatch__inner__do(M.msg_envelope(type: :call, recipient: recipient, settings: settings) = message) do
    case recipient_register(recipient) do
      {:dynamic, dispatcher, terms} ->
        apply(dispatcher, :__process__, [message| (terms || [])])
      {:ok, handle} -> {:ok, handle}
      M.link(process: pid) -> {:ok, pid}
      error -> error
    end
    |> case do
         {:dispatch, _dispatcher, :waiting, task} ->
           with {:ok, {:ok, handle}} <- Task.yield(task, timeout(settings)) do
             GenServer.call(handle, message, timeout(settings))
           else
             {:ok, error} -> error
             error -> error
           end
         {:ok, handle} -> GenServer.call(handle, message, timeout(settings))
         error -> error
       end
  end

  @doc """
  Validates and provides a reference to the recipient worker based on the given identifier.

  This function is used within the dispatching process to ensure that a valid recipient is specified for a message.

  `recipient_ref/1` performs pattern matching on different recipient types such as module reference or a messaging link. If the recipient format is unsupported, it returns an error tuple.

  This procedure ensures that messages are only sent to recognized and supported recipient types within the Noizu.AdvancedPool system.

  ## Examples

      # Obtains a reference to a worker based on the module and identifier
      Noizu.AdvancedPool.Message.Dispatch.recipient_ref(M.ref(module: MyWorker, identifier: :worker_id))

      # Returns an error when an unsupported recipient format is provided
      Noizu.AdvancedPool.Message.Dispatch.recipient_ref(:unsupported_format)

  """
  def recipient_ref(recipient)
  def recipient_ref(M.ref() = recipient), do: {:ok, recipient}
  def recipient_ref(M.link(recipient: recipient)) do
    recipient_ref(recipient)
  end
  def recipient_ref(recipient) do
    {:error, {:unsupported, recipient}}
  end

  # safe_call/1
  #--------------
  # Determines whether the safe dispatch option is enabled. If enabled, messages are sent within
  # a `try` block to catch any exceptions that might occur during dispatch.
  defp safe_call(M.settings(safe: v)), do: v
  defp safe_call(_), do: false

  # as_task/1
  #-----------
  # Checks if message dispatching should be executed asynchronously in a separate task.
  # If task setting is present, the message dispatch happens asynchronously.
  defp as_task(M.settings(task: v)), do: v
  defp as_task(_), do: false


  # timeout/1
  #-----------
  # Retrieves the timeout value from the settings. If not provided, a default timeout is used.
  # The timeout is critical for synchronous calls where the calling process waits for a response.
  defp timeout(M.settings(timeout: v)), do: v
  defp timeout(_), do: 5_000


  # recipient_register/2
  #----------------------
  # Resolves the recipient by finding the appropriate dispatcher based on the recipient's type.
  # It acts as a helper function to obtain the correct process handle for message delivery.
  defp recipient_register(recipient, hint \\ nil)
  defp recipient_register(M.ref(module: worker) = recipient, hint) do
    worker
    |> apply(:__dispatcher__, [])
    |> apply(:__handle__, [recipient, hint])
  end
  defp recipient_register(M.link(node: nil, process: nil, recipient: recipient), hint) do
    recipient_register(recipient, hint)
  end
  defp recipient_register(M.link(node: node, process: nil, recipient: recipient), hint) do
    recipient_register(recipient, hint || node)
  end
  defp recipient_register(M.link() = link, _) do
    link
  end
  defp recipient_register(M.server(recipient: recipient) = r, hint) do
    with {:ok, pool} <- recipient_pool(recipient) do
      pool
      |> apply(:__server__, [])
      |> apply(:__dispatcher__, [])
      |> apply(:__handle__, [r, hint])
    end
  end
  defp recipient_register(M.monitor(recipient: recipient) = r, hint) do
    with {:ok, pool} <- recipient_pool(recipient) do
      pool
      |> apply(:__monitor__, [])
      |> apply(:__dispatcher__, [])
      |> apply(:__handle__, [r, hint])
    end
  end
  defp recipient_register(M.worker_supervisor(recipient: recipient) = r, hint) do
    with {:ok, pool} <- recipient_pool(recipient) do
      pool
      |> apply(:__worker_supervisor__, [])
      |> apply(:__dispatcher__, [])
      |> apply(:__handle__, [r, hint])
    end
  end
  defp recipient_register(M.node_manager(recipient: recipient), hint) do
    Noizu.AdvancedPool.NodeManager
    |> apply(:__dispatcher__, [])
    |> apply(:__handle__, [recipient, hint])
  end

  # recipient_pool/1
  #-----------------
  # Determines the pool to which the provided recipient belongs. This information is used to
  # route the message to the correct pool, and subsequently to the right recipient within it.
  defp recipient_pool(M.link(recipient: inner)) do
    recipient_pool(inner)
  end
  defp recipient_pool(M.ref(module: m)) do
    {:ok, apply(m, :__pool__, [])}
  end
  defp recipient_pool(M.pool(recipient: recipient)) do
    with {:ok, pool} <- recipient_pool(recipient) do
      {:ok, pool}
    end
  end
  defp recipient_pool(M.server(recipient: recipient)) do
    with {:ok, pool} <- recipient_pool(recipient) do
      {:ok, pool}
    end
  end
  defp recipient_pool(M.monitor(recipient: recipient)) do
    with {:ok, pool} <- recipient_pool(recipient) do
      {:ok, pool}
    end
  end
  defp recipient_pool(M.worker_supervisor(recipient: recipient)) do
    with {:ok, pool} <- recipient_pool(recipient) do
      {:ok, pool}
    end
  end
  defp recipient_pool(M.node_manager(recipient: _recipient)) do
    {:ok, Noizu.AdvancedPool.NodeManager}
  end
end
