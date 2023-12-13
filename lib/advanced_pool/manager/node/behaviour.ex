defmodule Noizu.AdvancedPool.NodeManager.Configuration do

end

defmodule Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour do
  @moduledoc """
  Defines a contract for implementing node configuration management within the context of the AdvancedPool's NodeManager system. This behaviour module specifies the callbacks necessary for retrieving, caching, and storing node and global configurations.

  Implementers of this behaviour are expected to define the following functions:
    - `configuration/1` and `configuration/0`: Methods to obtain either node-specific or global configurations, respectively.
    - `cached/1` and `cached/0`: Methods for retrieving cached configurations, either globally or for a specific node.
    - `cache/2` and `cache/1`: Methods for caching new configuration data for a node or globally.

  These callbacks are utilized by the NodeManager to access updated configuration parameters critical to node operations within a distributed pool, including target thresholds for workload allocation and node participation details.

  Modules adhering to this behaviour will play a key role in dynamically capturing, updating, and distributing the operational parameters necessary for the efficient functioning of the AdvancedPool ecosystem.
  """

  @callback configuration(node) :: {:ok, term}
  @callback configuration() :: {:ok, term}

  @callback cached(node) :: {:ok, term}
  @callback cached() :: {:ok, term}

  @callback cache(node, term) :: {:ok, term}
  @callback cache(term) :: {:ok, term}

  require Record
  Record.defrecord(:target_window, target: nil, low: nil, high: nil)
  Record.defrecord(:node_service, state: :online, priority: nil, supervisor_target: nil, worker_target: nil, pool: nil, health_target: nil, node: nil)
  Record.defrecord(:cluster_service, state: :online, priority: nil, node_target: nil, worker_target: nil,  health_target: nil, pool: nil)
end

defmodule Noizu.AdvancedPool.NodeManager.ConfigurationManager do
  @moduledoc """
  Provides utilities for handling node and cluster configurations in relation to caching and retrieval operations. This module works alongside structures that implement the `Noizu.AdvancedPool.NodeManager.ConfigurationManagerBehaviour` to ensure that the configuration data flow is consistent and operationally sound within the NodeManager framework.

  The `ConfigurationManager` is fundamental in managing configuration changes and ensuring they are propagated throughout the cluster. It facilitates interactions with the configuration provider, offering the necessary interface for storing and retrieving configurations that support the diverse needs of the AdvancedPool environment.

  ## Primary Functions

  - `cache/1-2`: Caches configuration data, either globally or on a per-node basis, by invoking the appropriate caching functions of the provided configuration provider.
  - `cached/0-1`: Retrieves cached configuration information from the given configuration provider, ensuring updated and efficient access to this information.
  - `configuration/0-1`: Accesses the complete configuration settings from the configuration provider module.

  It is through this module that other system components query for updated configuration data, allowing for agility and responsive adaptation to system-wide policy changes.
  """

  def cache(provider, value) do
    apply(provider, :cache, [value])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
  
  def cache(provider, node, value) do
    apply(provider, :cache, [node, value])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
  
  def cached(provider) do
    apply(provider, :cached, [])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
  
  def cached(provider, node) do
    apply(provider, :cached, [node])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
  
  
  def configuration(provider) do
    apply(provider, :configuration, [])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
  
  def configuration(provider, node) do
    apply(provider, :configuration, [node])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
end
