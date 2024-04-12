AdvancedPool
================

## Introduction

AdvancedPool is an Elixir library designed for managing long-lived worker processes in distributed applications. It leverages OTP supervision trees and the `:syn` library to provide fault tolerance and efficient communication across a cluster of nodes.

The library facilitates:

*   Dynamic worker supervision and scaling.
*   Load balancing across a cluster. 
*   Health monitoring of nodes and services.
*   Reliable message routing with rerouting capabilities.
*   Flexible worker spawning strategies (lazy, asynchronous, synchronous).
*   Cluster management features like worker rebalancing and service deprovisioning.
*   Automatic removal of inactive worker processes.

AdvancedPool's architecture is based on a hierarchical supervisor structure: 

*   **ClusterManager:** Oversees the status of a multi machine/node server.
*   **NodeManager:** Oversees status of an individual node and contained services.
*   **PoolSupervisor:** Oversees the entire pool and its child supervisors on a specific Node.
*   **WorkerSupervisor:** Manages a set of "Segment Supervisors".
*   **Segment Supervisors:** Directly supervise individual worker processes (DynamicSupervisor), Workers are fanned out here to avoid bottle necks in GenServer internal records for tracking children, etc. 

This design ensures fault tolerance and enables efficient scaling and recovery from failures. 

The library provides a range of configuration options to customize worker targets, supervisor targets, health checks, timeouts, and other behaviors. 
It also allows for custom server and worker implementations to meet specific application requirements.

## Key Components and Terms

AdvancedPool utilizes a well-defined set of components to manage worker processes effectively:

*   **Pool:** Represents a group of long-lived processes dedicated to a specific service (e.g., UserPool, ChatRoomPool). 
*   **Pool.Worker:** Wraps user-defined entities implementing the `InnerStateBehaviour`. Handles initialization, message routing, automatic deprovisioning, and other maintenance tasks for individual workers.
*   **Pool.Server:** Responsible for forwarding requests to underlying workers, optimizing performance by performing worker spawning and PID lookups efficiently.
*   **Pool.PoolSupervisor:** The top-level supervisor in the pool's OTP tree, overseeing the entire pool's operation and ensuring fault tolerance.
*   **Pool.WorkerSupervisor:** Manages a layer of "Segment Supervisors" that directly supervise worker processes. 
*   **Pool.WorkerSupervisor.Seg[0-n]:** The second layer of the supervisor hierarchy, managing individual worker processes within segments. The number of segments is configurable to optimize performance and avoid bottlenecks caused by too many childen resident per supervisor.

### Pool

The `Pool` module serves as the main entry point for interacting with a specific pool of workers. It provides functions for:

*   Spawning workers.
*   Sending messages to workers (synchronous calls and asynchronous casts).
*   Retrieving worker information. 
*   Managing the pool's lifecycle (bringing online, taking offline).

Each pool module is generated using the `use Noizu.AdvancedPool` macro, which defines the basic structure and behavior of the pool. Developers can customize the pool's behavior by overriding default implementations and providing pool-specific configurations.

### Pool.Worker

The `Pool.Worker` module defines the behavior and functionalities of individual worker processes within a pool. Workers are responsible for processing tasks, managing their internal state, and responding to messages.

The `Noizu.AdvancedPool.Worker.Behaviour` provides a set of callbacks that workers must implement:

*   `init/3`: Initializes the worker with its reference, arguments, and context. 
*   `handle_call/3`: Handles synchronous calls from other processes. 
*   `handle_cast/2`: Handles asynchronous casts from other processes.
*   `handle_info/2`: Handles other messages and system events.
*   `terminate/2`: Performs cleanup tasks when the worker terminates.

Developers can extend the `Worker.Behaviour` to implement custom logic for their specific worker types.

### Pool.Server

The `Pool.Server` module acts as a message router, forwarding requests from clients to the appropriate worker processes within the pool. It optimizes performance by performing worker spawning and PID lookups within the calling thread or via off-process spawns, minimizing message passing overhead.

AdvancedPool provides a default server implementation that can be used directly or extended to implement custom routing logic. 

### Pool Supervisors

Pool supervisors play a crucial role in ensuring the fault tolerance and reliability of the worker pool system:

*   **PoolSupervisor:** The top-level supervisor oversees the entire pool and its child supervisors. It is responsible for starting and stopping the pool and restarting child processes in case of failures.
*   **WorkerSupervisor:** Manages a set of "Segment Supervisors" and is responsible for dynamically adding or removing segments as needed to scale the worker pool. 

### Visual Representation with `:syn` Routing:

```mermaid
graph LR;
    subgraph Pool
        PoolSupervisor --> WorkerSupervisor
        WorkerSupervisor --> Seg0
        WorkerSupervisor --> Seg1
        WorkerSupervisor --> ...
        WorkerSupervisor --> Segn
        subgraph Seg[Segment]
            Seg --> Worker
            Seg --> Worker
            Seg --> ...
            Seg --> Worker
        end
    end
    Pool --> Server
    Client --> Server
    Server --> :syn 
    :syn --> Worker
```

**Explanation of `:syn` Routing:**

*   The client sends a message to the `Pool.Server`.
*   The server forwards the message to the `:syn` registry, specifying the worker reference and the message.
*   The `:syn` registry efficiently resolves the worker reference to the corresponding PID and node where the worker is running. 
*   The message is then routed directly to the worker process for processing. 

This approach minimizes message passing overhead and allows for dynamic worker distribution across the cluster. 

**Example Code Snippet (Worker Definition):**

```elixir
defmodule MyPool.Worker do
  use Noizu.AdvancedPool.Worker.Behaviour

  defstruct [:identifier, :state]

  def init(ref, args, _context) do
    %__MODULE__{identifier: ref, state: args}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state.state, state}
  end
end
```

## How it Works

AdvancedPool's architecture and workflow are designed to ensure reliable and efficient management of worker processes in a distributed environment. 

### Architectural Overview: Hierarchical Supervisor Structure

At the heart of AdvancedPool lies a hierarchical supervisor structure that guarantees fault tolerance and scalability. The structure consists of three main layers:

*   **PoolSupervisor:** This top-level supervisor oversees the entire pool and its child supervisors, ensuring the pool's overall health and restarting child processes in case of failures.
*   **WorkerSupervisor:** Each WorkerSupervisor manages a set of "Segment Supervisors" and is responsible for dynamically adding or removing segments to adjust the pool's capacity based on workload demands.
*   **Segment Supervisors (Seg[0-n]):** These supervisors directly oversee individual worker processes. They are responsible for starting, stopping, and monitoring the workers within their segment.

This hierarchical design provides several benefits:

*   **Fault Tolerance:** If a worker process crashes, its Segment Supervisor automatically restarts it, ensuring service continuity. If a Segment Supervisor fails, the WorkerSupervisor restarts it, along with all the workers within that segment.
*   **Scalability:** The pool can be easily scaled by adding or removing WorkerSupervisors and segments as needed. This allows the system to adapt to changing workloads and optimize resource utilization. 
*   **Isolation:** Failures are isolated within segments, preventing cascading failures that could affect the entire pool. 

### Workflow Description: Worker Lifecycle and Message Passing 

The typical workflow for creating workers, sending messages, and handling responses involves the following steps:

1.  **Worker Creation:** When a new worker is needed, the system selects the optimal node and WorkerSupervisor based on configuration and runtime factors such as health, load, and capacity. The worker process is then spawned under the chosen supervisor. 
2.  **Message Routing:** Clients send messages to workers using their unique reference (e.g., an ID or a tuple). AdvancedPool utilizes the `:syn` registry to efficiently resolve the worker reference to the corresponding PID and node, ensuring the message is delivered to the correct worker process.
3.  **Message Handling:**  Workers process messages using the `handle_call`, `handle_cast`, and `handle_info` callbacks defined in the `Noizu.AdvancedPool.Worker.Behaviour`. These callbacks allow developers to implement custom logic for handling different types of messages and events.
4.  **Response Handling:** For synchronous calls, the worker sends a response back to the client. For asynchronous casts and info messages, no response is expected. 

### Code Snippets: Basic Interactions

**Creating a Worker:**

```elixir
# Spawn a worker with ID 123 and initial state %{data: "hello"}
MyPool.s_cast!(123, :init, %{data: "hello"}, context)
```

**Sending a Message to a Worker:**

```elixir
# Send a synchronous call to worker 123
{:ok, response} = MyPool.s_call(123, :get_state, context)

# Send an asynchronous cast to worker 123
MyPool.s_cast(123, :update_state, %{new_data: "updated"}, context) 
```

**Worker Implementation (handle_call example):**

```elixir
def handle_call(:get_state, _from, state) do
  {:reply, state.state, state}
end
```


## Key Features

AdvancedPool offers a comprehensive set of features designed to streamline worker management and ensure efficient and reliable operation in distributed Elixir applications. 

### Monitoring Services: Tracking Worker and Pool Health

AdvancedPool provides mechanisms for monitoring the health of both individual worker processes and the overall pool. This allows developers to proactively detect and address potential issues before they impact the system's stability or performance. 

**Health Checks:**

*   **Configurable health checks:** Define custom health check functions to assess the status of workers and services. 
*   **Health thresholds:**  Set thresholds for health metrics to trigger alerts or corrective actions. 
*   **Health reports:** Generate reports on the health of nodes, services, and workers to gain insights into the system's overall well-being.

**Example: Custom Health Check Function:**

```elixir
defmodule MyPool.Worker do
  # ... other worker code ...

  def handle_call(:check_health, _from, state) do
    # Perform health checks specific to your worker logic
    if state.status == :healthy do
      {:reply, :ok, state} 
    else
      {:reply, {:error, :unhealthy}, state}
    end
  end
end
```

### Load Balancing: Distributing Workload Across the Cluster

AdvancedPool employs various load balancing strategies to distribute worker processes across the cluster, ensuring optimal resource utilization and preventing bottlenecks. 

**Load Balancing Strategies:**

*   **Round-robin:** Distributes workers evenly across available nodes.
*   **Weighted round-robin:** Assigns weights to nodes based on factors like capacity or performance, distributing workers proportionally.
*   **Least loaded:**  Selects the node with the fewest active worker processes. 
*   **Health-based:** Prioritizes nodes with better health scores.

**Configuration Options:**

*   **Sticky sessions:** Configure worker processes to preferentially spawn on the same node they were spawned/requested from, improving locality and potentially reducing latency.
*   **Node and service priorities:** Assign priorities to nodes and services to influence node selection during worker spawning.

**Example Configuration (Sticky Sessions):**

```elixir
config :my_app, MyPool,
  worker: [
    sticky?: true 
  ] 
```

### Worker Counting and Process Checks: Monitoring Worker Status

AdvancedPool allows you to monitor the status of worker processes and track the number of active workers across the cluster. 

**Worker Status Checks:**

*   **Process checks:**  Determine if a worker process is alive or dead.
*   **Health checks:** Assess the health of individual workers using custom health check functions. 

**Worker Counting:**

*   **Track the number of active workers per node and service.**
*   **Monitor the overall worker count across the cluster.**

**Example: Checking Worker Status**

```elixir
# Check if worker 123 is alive
{:ok, is_alive} = MyPool.ping(123, context)
```

### Rapid Worker Resolution: Resolving References to PIDs and Nodes 

AdvancedPool efficiently resolves worker references (e.g., IDs or tuples) to their corresponding process identifiers (PIDs) and the nodes where they reside. This allows for direct communication with workers when necessary.

**Resolution Mechanism:**

*   **`:syn` registry:**  AdvancedPool utilizes the `:syn` registry to store and retrieve worker information, enabling fast and efficient lookups.
*   **Reference validation:**  The library validates worker references to ensure they are correctly formatted and correspond to existing worker processes. 

**Example: Retrieving Worker Process Information** 

```elixir
# Get the PID and node of worker 123
{:ok, {pid, node}} = MyPool.fetch(123, :process, context) 
```

## Enhanced Message Passing and Worker Management

AdvancedPool provides a sophisticated message-passing system and flexible worker management capabilities to ensure reliable communication and efficient resource utilization in distributed Elixir applications.

### Message Passing: Reliable Communication with Rerouting

AdvancedPool guarantees reliable message delivery to worker processes, even during worker lifecycle events like migration or respawn. This reliability is achieved through a combination of mechanisms:

*   **Message Envelopes:** All messages sent through AdvancedPool are wrapped in a `msg_envelope` record, which includes metadata such as:
    *   `recipient`: The identifier of the target worker (e.g., an ID or a tuple).
    *   `type`: The type of message (`:call` or `:cast`).
    *   `settings`: Configuration options for message delivery, including timeout, spawning behavior, and acknowledgement requirements.
*   **Routing and Resolution:** The `Noizu.AdvancedPool.DispatcherRouter` module handles message routing and worker resolution. 
    *   When a message is sent, the dispatcher first attempts to resolve the recipient worker's PID and node using the `:syn` registry.
    *   If the worker is not found and the message settings allow for spawning, the dispatcher initiates the worker creation process on an appropriate node. 
    *   Once the worker is available, the message is delivered directly to the worker process.
*   **Message Buffering:** If the target worker is temporarily unavailable (e.g., during migration or restart), the message is buffered and delivered once the worker becomes active again. 
*   **Failure Handling:** AdvancedPool handles message delivery failures gracefully, preventing message loss and ensuring system stability. 

**Example Message Envelope:**

```elixir
Noizu.AdvancedPool.Message.msg_envelope(
  recipient: {:ref, MyPool.Worker, 123},
  type: :call,
  settings: Noizu.AdvancedPool.Message.settings(
    spawn?: true,
    timeout: 5000
  ),
  msg: {:get_state, context}
)
```

### Worker Management: Flexible Spawning Strategies and Deprovisioning

AdvancedPool offers flexible worker spawning strategies and automatic deprovisioning mechanisms to optimize resource utilization and adapt to varying workloads.

**Worker Spawning Strategies:**

*   **`s_cast/3` and `s_cast!/3`:** These functions send asynchronous cast messages to workers. `s_cast!/3` ensures the worker is spawned if it doesn't exist, while `s_cast/3` does not.
*   **`s_call/3` and `s_call!/3`:** These functions send synchronous call messages to workers and wait for a response. Similar to casts, `s_call!/3` ensures worker spawning if necessary.
*   **Lazy Spawning:** This strategy spawns workers only when they are needed to process a message, conserving resources and avoiding unnecessary overhead.
*   **Asynchronous Spawning:** Workers are spawned in the background without blocking the calling process, improving responsiveness and allowing for concurrent worker initialization.
*   **Synchronous Spawning:** Workers are spawned and initialized before the calling process continues, ensuring the worker is immediately available to handle the message.

**Automatic Deprovisioning:**

*   AdvancedPool automatically removes inactive worker processes after a configurable period of inactivity. 
*   This feature helps to optimize resource usage and prevent memory leaks, especially in scenarios with dynamic workloads where workers may be created and destroyed frequently.

**Example: Lazy Spawning**

```elixir
# Send a message to a worker that may not exist yet
MyPool.s_cast!(123, :do_work, %{data: "important data"}, context) 
```

If worker 123 doesn't exist, it will be spawned lazily to process the message.

### Message Handling: Unpacking and Forwarding

The `Noizu.AdvancedPool.Message.Handle` module provides functions for unpacking message envelopes and forwarding messages to the appropriate worker processes.

*   **`unpack_call/3`, `unpack_cast/2`, and `unpack_info/2`:** These functions extract the message content and context from the envelope and forward it to the worker's `handle_call/3`, `handle_cast/2`, or `handle_info/2` callback, respectively.
*   **Recipient Validation:**  The handler functions perform recipient validation to ensure the message is intended for the correct worker process. If the recipient is incorrect, the message may be rerouted or dropped. 
*   **Worker State Check:** The handler functions also check the worker's state to ensure it is ready to process messages. If the worker is not yet initialized, the message may be buffered or an error may be returned.

**Example: Message Handling in Worker** 
``` 
defmodule MyPool.Worker do
  # ... other worker code ...
  def handle_call(msg_envelope() = call, from, state) do
    MessageHandler.unpack_call(call, from, state)
  end
  def handle_call({:get_state, _context}, _from, state) do
    {:reply, state.state, state}
  end
  def handle_call(msg, from, state) do
    super(msg, from, state)
  end
end
```

In this example, the worker's `handle_call/3` function receives the unpacked message (`:get_state`) and the current state. It then returns the worker's state as the response. 


## Configuration Options

AdvancedPool provides a flexible configuration system that allows developers to customize the behavior of the library to suit their specific needs and application requirements.

### Available Configuration Options

*   **OTP Application Configuration:**
    *   `supervisor`: The module responsible for supervising the pool's processes. Defaults to `Noizu.AdvancedPool.DefaultSupervisor`.
    *   `server`: The module responsible for handling client requests and routing messages to workers. Defaults to `Noizu.AdvancedPool.Server.DefaultServer`. 
    *   `worker_server`: The GenServer module used for individual worker processes. Defaults to `Noizu.AdvancedPool.Worker.Server`. 
*   **Pool Configuration:**
    *   `stand_alone`: A boolean flag indicating whether the pool operates in standalone mode or as part of a cluster. Defaults to `false` (clustered mode).
*   **Worker Configuration:** 
    *   `target`: A `target_window` struct defining the desired number of worker processes for the service, including low, target, and high thresholds. These thresholds influence worker spawning and load balancing decisions. 
    *   `sticky?`: A boolean flag enabling or disabling sticky sessions for worker processes. When enabled, workers will preferentially spawn on the same node where they were previously active, assuming the node meets health and capacity requirements. 
*   **Worker Supervisor Configuration:**
    *   `worker`: A nested configuration for worker settings specific to the worker supervisor. 
    *   `init`: Options related to the initial state of the worker supervisor. 
        *   `status`: The initial status of the worker supervisor (e.g., `:online`, `:offline`). 
*   **Cluster Configuration:** 
    *   Defines settings for each service at the cluster level.
    *   `state`: The desired state of the service across the cluster (e.g., `:online`, `:offline`).
    *   `priority`: An integer value indicating the service's priority for worker placement and load balancing. Higher priority services are given preference during node selection.
    *   `node_target`: A `target_window` struct defining the desired number of nodes in the cluster that should run the service. 
    *   `worker_target`: A `target_window` struct specifying the target number of worker processes for the service across the entire cluster.
    *   `health_target`: A `target_window` struct defining the health target for the service. This target is used during health checks and influences load balancing decisions. 
*   **Node Configuration:**
    *   Defines service-specific settings on individual nodes. 
    *   `state`: The desired state of the service on the specific node. 
    *   `priority`: The service's priority on the node, influencing worker placement and load balancing decisions within the node.
    *   `supervisor_target`: A `target_window` struct defining the target number of worker supervisors for the service on the node.
    *   `worker_target`: A `target_window` struct specifying the target number of worker processes for the service on the node. 
    *   `health_target`: A `target_window` struct defining the health target for the service on the node. 

### Code Examples: Configuring AdvancedPool

**Example 1: Basic Configuration**

```elixir
config :my_app, MyPool,
  worker: [
    target: target_window(low: 100, target: 500, high: 1000) 
  ]
```

This configuration sets the target number of workers for the `MyPool` service to 500, with a low threshold of 100 and a high threshold of 1000.

**Example 2: Sticky Sessions and Custom Server** 

```elixir
config :my_app, MyPool,
  otp: [
    server: MyPool.CustomServer
  ],
  worker: [
    sticky?: true 
  ]
```

This configuration enables sticky sessions for workers in `MyPool` and specifies a custom server module `MyPool.CustomServer` for handling client requests and routing messages. 

**Example 3: Cluster and Node-Specific Settings**

```elixir
# Configuration in NodeManager.ConfigurationProvider

def configuration(node) do
  case node do
    :"node1@example.com" -> 
      %{
        MyPool: node_service(
          pool: MyPool,
          node: node,
          state: :online, 
          priority: 1,
          supervisor_target: target_window(target: 2, low: 1, high: 3),
          worker_target: target_window(target: 500, low: 250, high: 750)
        )
      } 
    :"node2@example.com" ->
      %{
        MyPool: node_service(
          pool: MyPool, 
          node: node, 
          state: :online,
          priority: 0,
          supervisor_target: target_window(target: 1, low: 1, high: 2),
          worker_target: target_window(target: 250, low: 125, high: 375)
        ) 
      }
  end
end

def configuration() do
  %{
    MyPool: cluster_service( 
      pool: MyPool, 
      state: :online,
      priority: 10, 
      node_target: target_window(target: 2, low: 1, high: 3),
      worker_target: target_window(target: 750, low: 375, high: 1125)
    )
  }
end
```

This example demonstrates how to configure AdvancedPool for a cluster with two nodes. It defines node-specific settings for the `MyPool` service on each node and specifies cluster-level settings as well. 

## Getting Started

### Installation

To install AdvancedPool, add it as a dependency in your `mix.exs` file:

```elixir
def deps do
  [
    {:advanced_pool, "~> 3.0"}
  ]
end
```

Then, run `mix deps.get` to fetch and install the library.

### Basic Usage Example

Here's a step-by-step example demonstrating how to set up a pool, create workers, and send messages using AdvancedPool:

**1. Define Your Worker Module:**

```elixir
defmodule MyPool.Worker do
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M
  alias Noizu.AdvancedPool.Message.Handle, as: MessageHandler
  require Logger

  defstruct [:identifier, :count]
  # After defstruct!
  use Noizu.AdvancedPool.Worker.Behaviour


  def init(ref, _args, _context) do
    # Initialize worker state
    %__MODULE__{identifier: ref, count: 0}
  end

  def handle_call(msg_envelope() = call, from, state) do
    MessageHandler.unpack_call(call, from, state)
  end
  def handle_call(:increment, _from, state) do
    # Increment the count and return the updated state
    {:reply, state.count + 1, %{state | count: state.count + 1}}
  end
  def handle_call(msg, from, state) do
    super(msg, from, state)
  end

end
```

This worker module defines a simple worker that maintains a counter. The `handle_call/3` function increments the counter when it receives an `:increment` message and returns the updated count as the response.

**2. Define Your Pool Module:**

```elixir
defmodule MyPool do
  use Noizu.AdvancedPool
  Noizu.AdvancedPool.Server.default()

  def __worker__(), do: MyPool.Worker

  def increment(worker_id, context) do
    # Send a synchronous call to increment the worker's counter
    s_call(worker_id, :increment, context)
  end
end
```

This pool module uses the `use Noizu.AdvancedPool` macro to define the basic structure and behavior of the pool. It also specifies the worker module (`MyPool.Worker`) and provides a convenience function `increment/2` for sending an `:increment` message to a worker.

**3. Start the Pool and Interact with Workers:**

```elixir
# Start the pool supervisor
{:ok, _sup} = MyPool.PoolSupervisor.start_link(context)

# Bring the pool online in the cluster
MyPool.bring_online(context)

# Create a worker with ID 123
MyPool.s_cast!(123, :init, [], context)

# Increment the worker's counter and retrieve the updated value
{:ok, count} = MyPool.increment(123, context)

# Print the count
IO.puts("Current count: #{count}")
```

This code snippet demonstrates how to start the pool supervisor, bring the pool online, create a worker, and interact with the worker by sending a message to increment its counter. 

**Additional Notes:**

*   The `context` variable is used to pass additional information and metadata to worker processes.
*   AdvancedPool provides various other functions for interacting with workers, such as `s_cast/3`, `s_call!/3`, `fetch/3`, and `kill!/3`. 
*   You can customize the behavior of the pool and worker processes by overriding default implementations and providing pool-specific configurations.

## Advanced Usage

AdvancedPool offers various options for customizing and extending its behavior to suit specific application requirements. This section covers advanced usage patterns for worker customization, server configuration, and dynamic worker supervision.

### Custom Worker Behavior: Extending `Noizu.AdvancedPool.Worker.Behaviour` 

The `Noizu.AdvancedPool.Worker.Behaviour` provides a set of callback functions that define the expected behavior of worker processes. Developers can extend this behavior to implement custom logic for their specific worker types.

**Available Callbacks:**

*   `init/3`: Initializes the worker with its reference, arguments, and context.
*   `handle_call/3`: Handles synchronous calls from other processes.
*   `handle_cast/2`: Handles asynchronous casts from other processes.
*   `handle_info/2`: Handles other messages and system events.
*   `terminate/2`: Performs cleanup tasks when the worker terminates.
*   `load/2`: Loads or reloads the worker's state.
*   `reload!/2`: Forces a reload of the worker's state.
*   `fetch/3`: Retrieves information from the worker (e.g., its state or process information).
*   `ping/2`: Checks the responsiveness of the worker.
*   `kill!/2`: Terminates the worker process.
*   `crash!/2`: Intentionally crashes the worker process (for testing purposes).
*   `hibernate/2`: Puts the worker into a hibernation state to conserve resources. 
*   `persist!/2`: Persists the worker's state. 

**Example: Custom Worker with State Persistence**

```elixir
defmodule MyPool.PersistentWorker do
  use Noizu.AdvancedPool.Worker.Behaviour

  defstruct [:identifier, :state]

  def init(ref, args, _context) do
    # Load state from persistent storage or initialize it
    initial_state = load_state(ref) || args
    %__MODULE__{identifier: ref, state: initial_state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state.state, state}
  end

  def handle_cast(:update_state, %{new_state: new_state} = _msg, state) do
    # Update state and persist it to storage
    updated_state = %{state | state: new_state}
    persist_state(state.identifier, updated_state)
    {:noreply, updated_state}
  end

  defp load_state(ref) do
    # Implement logic to load state from persistent storage
  end

  defp persist_state(ref, state) do
    # Implement logic to persist state to storage 
  end
end
```

This example demonstrates a worker that persists its state to a storage backend. The `init/3` function loads the state during initialization, and the `handle_cast/2` function persists the state whenever it is updated.

### Server Customization: Configuring and Extending Server Behavior

The `Pool.Server` module handles client requests and routes messages to worker processes. AdvancedPool provides a default server implementation, but developers can customize or extend this behavior to meet specific needs.

**Options for Server Customization:**

*   **Configure the `server` option in your pool's configuration to use a custom server module.**
*   **Extend the `Noizu.AdvancedPool.Server.DefaultServer` module to inherit its default behavior and add custom functionality.**
*   **Implement the `GenServer` behavior directly in your custom server module.** 

**Example: Custom Server with Priority Routing**

```elixir
defmodule MyPool.PriorityServer do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:ok, opts}
  end

  def handle_call({:call, worker_id, message, priority}, _from, state) do
    # Implement priority-based routing logic here
    # ... 
  end

  # Implement other GenServer callbacks as needed 
end
```

This example demonstrates a custom server that handles messages with priorities. The routing logic within the `handle_call/3` function could prioritize messages based on their assigned priority levels.

### Dynamic Worker Supervision: Adding and Removing Worker Supervisors

AdvancedPool allows for dynamic scaling of the worker pool by adding and removing worker supervisors at runtime. This enables the system to adapt to changing workloads and optimize resource utilization.

**Adding Worker Supervisors:**

*   **Use the `MyPool.add_worker_supervisor/2` function to add a new worker supervisor to the pool.** 
*   **Specify the node where the supervisor should be started and provide a supervisor specification.**

**Removing Worker Supervisors:**

*   **Use the `DynamicSupervisor` API to terminate worker supervisors.** 

**Example: Adding a Worker Supervisor**

```elixir
# Add a worker supervisor to the node :"node2@example.com"
MyPool.add_worker_supervisor(:"node2@example.com", MyPool.WorkerSupervisor.spec(MyPool, context))
```

This code snippet adds a new worker supervisor for the `MyPool` service on the specified node. 

## Deployment Considerations

Deploying AdvancedPool in a production environment requires careful consideration of cluster configuration, monitoring, and scaling strategies to ensure optimal performance and reliability.

### Production Environment Setup: Cluster Configuration and Monitoring

**Cluster Configuration:**

*   **Node Configuration:** Define the participating nodes and services available on each node in the `NodeManager.ConfigurationProvider` module.
*   **Service Configuration:** Specify the desired state, priority, target worker counts, and health targets for each service on each node. 
*   **Network Connectivity:** Ensure reliable network connectivity between nodes in the cluster.
*   **Elixir Distribution:** Configure Elixir distribution settings (e.g., Erlang cookie) for secure communication between nodes.

**Monitoring:**

*   **Node and Service Health:** Monitor the health of nodes and services using the health check mechanisms provided by AdvancedPool. 
*   **Worker Process Status:**  Track the status of worker processes to identify potential issues or failures.
*   **Resource Utilization:** Monitor CPU, memory, and network usage on each node to ensure efficient resource allocation.
*   **Message Queues:**  Observe message queue lengths to identify potential bottlenecks or backpressure.

**Recommended Tools and Practices:**

*   **Telemetry:** Utilize the Telemetry library to collect and aggregate metrics from AdvancedPool and your application. 
*   **Observability Platforms:** Integrate with observability platforms like Datadog, Honeycomb, or Prometheus to visualize and analyze system behavior.
*   **Alerting:** Set up alerts for critical events, such as node failures, service outages, or unhealthy worker processes.
*   **Logging:**  Log relevant events and errors to facilitate troubleshooting and diagnostics. 

### Scaling Strategies: Adapting to Workload Demands

Scaling an AdvancedPool cluster involves adjusting the number of nodes and worker processes to meet changing workload demands and performance requirements. 

**Horizontal Scaling (Adding Nodes):**

*   Add new nodes to the cluster to distribute the workload across more machines, improving overall capacity and fault tolerance. 
*   Ensure proper configuration of the new nodes in the `NodeManager.ConfigurationProvider` and adjust service configurations as needed.
*   Consider using a cluster management tool like Kubernetes or Nomad to automate node provisioning and configuration.

**Vertical Scaling (Adding Workers):**

*   Increase the target number of workers for services on existing nodes to handle higher workloads.
*   Add more worker supervisors to a node to distribute the worker processes more efficiently. 
*   Monitor resource utilization to ensure that adding workers does not lead to resource contention or performance degradation. Keep an eye on reduction counts (see live dashboard)

**Scaling Strategies Based on Workload Characteristics:**

*   **CPU-bound workloads:** Consider vertical scaling by adding more workers or upgrading the hardware on existing nodes.
*   **Memory-bound workloads:**  Evaluate horizontal scaling by adding more nodes to distribute the memory requirements. 
*   **I/O-bound workloads:**  Analyze the need for horizontal scaling to distribute I/O operations across multiple nodes.

**Dynamic Scaling:**

*   AdvancedPool's dynamic worker supervision capabilities allow for automatic scaling based on workload demands. 
*   Configure health checks and thresholds to trigger automatic worker spawning or deprovisioning based on metrics like CPU usage or message queue length. 

**Monitoring and Performance Tuning:**

*   Continuously monitor the performance of your AdvancedPool cluster and make adjustments to configuration and scaling strategies as needed. 
*   Identify bottlenecks and optimize resource utilization to ensure efficient operation. 
*   Fine-tune worker supervisor and worker target configurations to achieve the desired balance between performance and resource consumption.

## Troubleshooting

While AdvancedPool is designed for reliability and robustness, occasional issues may arise in production environments. This section covers common problems encountered when using AdvancedPool and provides guidance on troubleshooting and resolving them. 

### Common Issues and Solutions

**1. Worker Processes Crashing or Becoming Unresponsive:**

*   **Check worker logs:** Examine the logs of the affected worker processes for any error messages or exceptions that may indicate the cause of the crash. 
*   **Analyze worker code:** Review the worker's implementation for potential bugs or logic errors that could lead to crashes. 
*   **Monitor resource usage:**  Ensure that the worker processes have sufficient resources (CPU, memory) and are not experiencing resource contention.
*   **Check for deadlocks:**  Investigate the possibility of deadlocks or race conditions in the worker code that could cause the processes to become unresponsive.
*   **Review supervision strategy:** Ensure that the worker supervisors are configured to restart crashed workers appropriately. 

**2. Messages Not Being Delivered or Processed:**

*   **Verify worker status:** Check if the target worker process is alive and healthy using the `ping/2` function or by inspecting the worker's state. 
*   **Examine message queues:** Observe message queue lengths to identify potential bottlenecks or backpressure that could prevent message delivery.
*   **Check routing configuration:** Ensure that the message routing configuration in the `NodeManager.ConfigurationProvider` is correct and that messages are being routed to the intended worker processes.
*   **Validate worker references:**  Ensure that the worker references used in message sending functions are valid and correspond to existing worker processes. 

**3. Load Balancing Issues:**

*   **Review load balancing strategy:** Ensure that the chosen load balancing strategy is appropriate for your workload characteristics and cluster configuration.
*   **Check node and service priorities:** Verify that priorities assigned to nodes and services are correctly influencing worker placement decisions.
*   **Monitor node health:** Ensure that unhealthy nodes are not receiving a disproportionate share of the workload.
*   **Adjust worker target configurations:**  Fine-tune worker target thresholds to achieve the desired balance between load distribution and resource utilization.

**4. Performance Degradation:** 

*   **Profile application:** Use profiling tools to identify performance bottlenecks in your application code or in the AdvancedPool library itself.
*   **Monitor resource usage:**  Track CPU, memory, and network usage on each node to detect resource contention or inefficient resource allocation. 
*   **Optimize worker code:** Review worker implementations for potential optimizations to reduce CPU or memory usage. 
*   **Adjust worker spawning strategies:** Evaluate whether lazy or asynchronous spawning could improve performance by reducing the number of active worker processes.

**5. Cluster Management Challenges:** 

*   **Node failures:** Handle node failures gracefully by ensuring proper configuration of worker supervisors and implementing mechanisms for rebalancing workers across the remaining nodes in the cluster.
*   **Network partitions:** Design your application to tolerate network partitions and implement strategies for handling message delivery and worker coordination during network disruptions.
*   **Rolling updates:** Perform rolling updates of your application and AdvancedPool library to minimize downtime and ensure smooth transitions. 

### Troubleshooting Tips

*   **Enable detailed logging:** Configure AdvancedPool and your application to log relevant events, errors, and debug information to facilitate troubleshooting.
*   **Use tracing tools:** Utilize tracing tools like Erlang's `:dbg` or third-party libraries to trace message flow and worker interactions.
*   **Inspect worker state:** Use the `fetch/3` function or other mechanisms to inspect the state of worker processes and identify potential issues.
*   **Monitor system metrics:** Continuously monitor key system metrics such as CPU usage, memory consumption, and message queue lengths to detect anomalies and potential problems.
*   **Consult the AdvancedPool documentation and community resources:** Refer to the library's documentation and seek help from the Elixir community or the AdvancedPool maintainers for assistance with troubleshooting complex issues. 

**By understanding common problems and employing effective troubleshooting techniques, you can ensure the smooth operation and optimal performance of your AdvancedPool-based distributed applications.** 


## Contributing

Contributions to AdvancedPool are welcome and encouraged! We value community involvement in improving and extending the library's functionality.

### Contribution Guidelines

To contribute to AdvancedPool, please follow these guidelines:

*   **Fork the repository:** Create a fork of the AdvancedPool repository on GitHub.
*   **Create a branch:**  Branch off from the `main` branch for your changes. Use a descriptive branch name that reflects the purpose of your contribution.
*   **Follow code style:**  Adhere to the existing code style and conventions used in the AdvancedPool codebase. This helps maintain code readability and consistency.
*   **Write tests:**  Include unit and integration tests for your code changes to ensure functionality and prevent regressions. AdvancedPool uses the ExUnit testing framework.
*   **Update documentation:** If your contribution introduces new features or changes existing behavior, update the documentation accordingly. 
*   **Submit a pull request:** Once your changes are ready, submit a pull request to the `main` branch of the AdvancedPool repository. Provide a clear and concise description of your changes and the problem they address.

**Additional Considerations:**

*   **Coding style:** We recommend following the Elixir Style Guide for code formatting and conventions.
*   **Testing:** Ensure that your tests cover both positive and negative cases and provide sufficient coverage for your code changes.
*   **Documentation:** Use clear and concise language in your documentation updates, providing examples where appropriate. 

We appreciate your contributions to AdvancedPool!


Related Technology
---------------------------
- [AdvancedElixirScaffolding](https://github.com/noizu-labs/advanced_elixir_scaffolding) - This library provides scaffolding for working with DomainObjects and Repos, access control, and including unique identifer ref tuples and protocols for converting between domain objects and ref tuples or vice versa.
- [ElixirCore](https://github.com/noizu/ElixirCore) - Support for tracking call context between layers.  Entity Reference Protocols, OptionHelper support for compile time options with defaults/and required field type and presence validation. 
- [MnesiaVersioning](https://github.com/noizu/MnesiaVersioning) - Simple Change Management Library for Mnesia/Amnesia. (although it's often more expedient if also using ecto to move operations into changesets and add some task aliases so ecto operations/setup etc. start/stop/teardown mnesia databases. 
- [[AdvancedKitchenSink](https://github.com/noizu/KitchenSinkAdvanced)](https://github.com/noizu-labs/KitchenSinkAdvanced) - Various useful libraries and tools that integrate with SimplePool and ElixirScaffolding. (CMS, Transactional Emails, SmartTokens, ...)
- [RuleEngine](https://github.com/noizu/RuleEngine) - Extensible DB Driven Scripting/RuleEngine Library. 

Additional Documentation
----------------------------
* [Api Documentation](http://noizu.github.io/SimplePool)
