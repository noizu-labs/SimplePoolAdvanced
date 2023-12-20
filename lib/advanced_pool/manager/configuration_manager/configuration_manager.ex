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

  def lock_node(provider, node) do
    apply(provider, :lock_node, [node])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
  def release_node(provider, node) do
    apply(provider, :release_node, [node])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end

  def lock_node_service(provider, node, service) do
    apply(provider, :lock_node_service, [node, service])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
  def release_node_service(provider, node, service) do
    apply(provider, :release_node_service, [node, service])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end

  def report_cluster_health(provider, report) do
    apply(provider, :report_cluster_health, [report])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
  def report_node_health(provider, node, report) do
    apply(provider, :report_node_health, [node, report])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end
  def report_node_service_health(provider, node, service, report) do
    apply(provider, :report_node_service_health, [node, service, report])
  rescue e -> {:error, e}
  catch :exit, e -> {:error, {:exit, e}}
    e -> {:error, e}
  end

end
