defmodule Noizu.AdvancedPool.Message do
  @moduledoc """
  Provides data structures for managing and operating on messages within the AdvancedPool system.

  This module defines various records that represent the different components involved in message passing,
  such as acknowledgments, links to processes and nodes, various recipient entities, and settings for message dispatch behavior. It also includes helper functions to interpret these records and extract relevant information.

  The `ack` record captures acknowledgment details, indicating various types of acknowledgment necessary
  for message processing.

  The `link` record holds references to nodes, processes, and recipients to facilitate targeted
  message delivery throughout the system.

  General server (`gen_server`), pool (`pool`), server (`server`), monitor (`monitor`),
  worker supervisor (`worker_supervisor`), and other related records store references to specific components involved
  in messaging, allowing AdvancedPool system to communicate across its various modules and processes.

  The `ref` record provides a universal identifier linking to objects that can be unpacked without
  prior knowledge of entity type, following the EntityReferenceProtocol.

  The `settings` record centralizes the configurations for message dispatch behavior, including safety features,
  asynchronous execution, acknowledgment, and timeout constraints.

  Records `s` and `msg_envelope` standardize the structure of messages being dispatched,
  including call details, context, and settings.

  The module supports AdvancedPool's messaging requirements, ensuring robust communicati
  on and process coordination across the pool's distributed architecture.
  """

  require Record


  # Ack record is used to define acknowledgement types for messaging within the pool.
  # Types include receipt acknowledgment, process acknowledgment, link update, response, or none.
  @type ack_type :: :receipt | :process | :link_update | :response | :none | nil
  Record.defrecord(:ack, type: nil, to: nil)
  @type ack :: record(:ack, type: ack_type() | atom(), to: any())

  #------------------------
  # Recipient
  #------------------------

  # Link record is used to keep a reference to a node, process, and recipient for messaging purposes.
  # This is utilized across the system to address messages to a specific worker or service.
  Record.defrecord(:link, node: nil, process: nil, recipient: nil)
  @type link :: record(:link, node: any() | nil, process: pid() |  term() | nil, recipient: any() | nil)

  # General server record for specifying a module that will act as a GenServer.
  # This can be used to encapsulate behavior related to a GenServer across the system.
  Record.defrecord(:gen_server, module: nil)
  @type gen_server :: record(:gen_server, module: module() | nil)

  # Pool record is for storing a generic recipient reference related to a worker pool.
  Record.defrecord(:pool, recipient: nil)
  @type pool :: record(:pool, recipient: any() | nil)

  # Server record is used to keep references to server components within the pool, allowing for messaging.
  Record.defrecord(:server, recipient: nil)
  @type server :: record(:server, recipient: any() | nil)


  # Monitor record is used to reference a monitoring service, typically for supervising worker processes.
  Record.defrecord(:monitor, recipient: nil)
  @type monitor :: record(:monitor, recipient: any() | nil)


  # Worker supervisor record stores a reference that allows for messaging to worker supervisors.
  Record.defrecord(:worker_supervisor, recipient: nil)
  @type worker_supervisor :: record(:worker_supervisor, recipient: any() | nil)

  # Target node record stores a reference to a specific node, usually for task distribution or load balancing.
  Record.defrecord(:target_node, node: nil)
  @type target_node :: record(:target_node, node: term() | nil)

  # Node manager record maintains a reference to a node manager service, for coordinating nodes in the pool.
  Record.defrecord(:node_manager, recipient: nil)
  @type node_manager :: record(:node_manager, recipient: any() | nil)

  # Reference record for identifying and communicating with specific worker processes by a module and identifier.
  # Typically moved to Elixir core, but used here for internal referencing. Additionally provided universal identifier
  # link to object that can be unpacked with out knowing the entity type in advance using the EntityReferenceProtocol
  Record.defrecord(:ref, module: nil, identifier: nil) # move to elixir core.
  @type ref :: record(:ref, module: module() | nil, identifier: any() | nil)

  # Settings record encapsulates various configuration options used when dispatching messages.
  # It includes options for message safety, spawning behavior, task creation, acknowledgments, stickiness, and timeouts.
  Record.defrecord(:settings, safe: nil, spawn?: nil, task: nil, ack?: nil, sticky?: nil, timeout: nil)
  @type settings :: record(:settings, safe: boolean() | nil, spawn?: boolean() | nil, task: term() | nil, ack?: boolean() | nil, sticky?: boolean() | nil, timeout: non_neg_integer() | nil | :infinity)


  # Msg and msg_envelope records are for encapsulating information about a message being sent.
  # They provide a uniform approach to crafting and using messages across the system.
  Record.defrecord(:s, call: nil, context: nil, options: nil)
  @type s :: record(:s, call: any(), context: any() | nil, options: any() | nil)

  Record.defrecord(:msg_envelope,
    identifier: nil,
    type: nil,
    recipient: nil,
    settings: nil,
    msg: nil
  )
  @type msg_envelope :: record(:msg_envelope, identifier: any() | nil, type: any() | nil, recipient: any() | nil, settings: settings() | nil, msg: any())


  Record.defrecord(
    :pool_status,
    status: :initializing,
    service: nil,
    health: nil,
    node: nil,
    worker_count: 0,
    worker_target: nil,
    updated_on: nil
  )
  Record.defrecord(
    :worker_sup_status,
    status: :initializing,
    service: nil,
    health: nil,
    node: nil,
    worker_count: 0,
    worker_target: nil,
    updated_on: nil
  )

  Record.defrecord(:cluster_status, node: nil, status: nil, manager_state: nil, health_index: 0.0, started_on: nil, updated_on: nil)


  Record.defrecord(:node_status, node: nil, status: nil, manager_state: nil, health_index: 0.0, started_on: nil, updated_on: nil)

  Record.defrecord(:health_check, worker: 0.0, worker_sup: 0.0, error_rate: 0.0, warning_rate: 0.0)

  Record.defrecord(:target_window, target: nil, low: nil, high: nil)
  Record.defrecord(:node_service, state: :online, priority: nil, supervisor_target: nil, worker_target: nil, pool: nil, health_target: nil, node: nil)
  Record.defrecord(:cluster_service, state: :online, priority: nil, node_target: nil, worker_target: nil,  health_target: nil, pool: nil)

  # Used in ETS with update_counter, order must not be altered when extending.
  Record.defrecord(:worker_events, {:service, :_}, [init: 0, terminate: 0, sup_init: 0, sup_terminate: 0, error: 0, warning: 0, started_on: 0, refreshed_on: 0, meta: nil])

  @doc """
  Given an optional settings record, it determines whether the passed message should remain sticky to the node/process that handled it last. Returns `true` if it should, otherwise `false`.

  A sticky message may be useful in scenarios where message continuity or session affinity is required, like ensuring subsequent related message handling occurs on the same node or process.

  ## Examples

      iex> Noizu.AdvancedPool.Message.sticky?(nil)
      false

      iex> Noizu.AdvancedPool.Message.sticky?(settings(sticky?: true))
      true
  """
  def sticky?(settings(sticky?: v)), do: v
  def sticky?(_), do: false



  @doc """
  Checks whether a new process should be spawned when dispatching a message. Returns `true` for spawning a new process and `false` otherwise.

  Spawning could be necessary for handling messages that require isolated or concurrent processing.

  ## Examples

      iex> Noizu.AdvancedPool.Message.spawn?(nil)
      false

      iex> Noizu.AdvancedPool.Message.spawn?(settings(spawn?: true))
      true
  """
  def spawn?(settings(spawn?: v)), do: v
  def spawn?(_), do: false


  @doc """
  Determines if an acknowledgment is expected after processing a message. Returns `true` if acknowledgment is expected, otherwise `false`.

  Acknowledgments can be used to confirm receipt or handling of messages, thereby providing a means of tracking and ensuring message delivery.

  ## Examples

      iex> Noizu.AdvancedPool.Message.ack?(nil)
      false

      iex> Noizu.AdvancedPool.Message.ack?(settings(ack?: true))
      true
  """
  def ack?(settings(ack?: v)), do: v
  def ack?(_), do: false


  @doc """
  Extracts the timeout value from a settings record which specifies how long to wait for a response when sending messages. Returns `nil` if no timeout is set.

  Timeouts help ensure that message callers are not indefinitely blocked waiting for a response, thus could be used for enforcing message delivery SLAs and preventing resource deadlocks.

  ## Examples

      iex> Noizu.AdvancedPool.Message.timeout(nil)
      nil

      iex> Noizu.AdvancedPool.Message.timeout(settings(timeout: 5000))
      5000
  """
  def timeout(settings(timeout: v)), do: v
  def timeout(_), do: nil

  @doc """
  Determines whether to use a safe dispatch mechanism when sending messages. Returns value from settings, or `nil` if not set.

  Safe dispatch can provide additional error and exception handling around message dispatching to protect from unforeseen errors during message delivery.

  ## Examples

      iex> Noizu.AdvancedPool.Message.safe(nil)
      nil

      iex> Noizu.AdvancedPool.Message.safe(settings(safe: true))
      true
  """
  def safe(settings(safe: v)), do: v
  def safe(_), do: nil

  @doc """
  Determines whether the message dispatch should result in the creation of a task (asynchronously). Returns the task identifier if set, otherwise `nil`.

  Using tasks allows operations to be processed in the background, not blocking the calling process.

  ## Examples

      iex> Noizu.AdvancedPool.Message.task(nil)
      nil

      iex> Noizu.AdvancedPool.Message.task(settings(task: :my_task))
      :my_task
  """
  def task(settings(task: v)), do: v
  def task(_), do: nil

  @doc """
  Extracts the calling context from a message structure.

  The call context typically contains metadata about the operation being performed, such as the origin of the request, any associated transaction data, or other contextual information that may be required during message processing.

  If no context is provided with the message structure, this function returns `nil`.

  ## Examples

      iex> Noizu.AdvancedPool.Message.call_context(nil)
      nil

      iex> Noizu.AdvancedPool.Message.call_context(s(context: %Noizu.ElixirCore.CallingContext{}))
      %Noizu.ElixirCore.CallingContext{}
  """
  def call_context(nil), do: nil
  def call_context(s(context: v)), do: v

end
