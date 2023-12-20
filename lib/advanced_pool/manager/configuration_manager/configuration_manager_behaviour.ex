
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

  @callback lock_node(node) :: {:ok, term} | {:error, term}
  @callback release_node(node) :: {:ok, term} | {:error, term}
  @callback lock_node_service(node, service  :: term) :: {:ok, term} | {:error, term}
  @callback release_node_service(node, service :: term) :: {:ok, term} | {:error, term}

  @callback report_cluster_health(report :: term) :: {:ok, term} | {:error, term}
  @callback report_node_health(node, report :: term) :: {:ok, term} | {:error, term}
  @callback report_node_service_health(node, service :: term, report :: term) :: {:ok, term} | {:error, term}

end
