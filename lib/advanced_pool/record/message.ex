defmodule Noizu.AdvancedPool.Message do
  require Record

  # Ack
  @type ack_type :: :receipt | :process | :link_update | :response | :none | nil
  Record.defrecord(:ack, type: nil, to: nil)

  # Recipient
  Record.defrecord(:link, node: nil, process: nil, recipient: nil)
  Record.defrecord(:gen_server, module: nil)
  Record.defrecord(:pool, recipient: nil)
  Record.defrecord(:server, recipient: nil)
  Record.defrecord(:monitor, recipient: nil)
  Record.defrecord(:worker_supervisor, recipient: nil)
  Record.defrecord(:target_node, node: nil)
  Record.defrecord(:node_manager, recipient: nil)
  Record.defrecord(:ref, module: nil, identifier: nil) # move to elixir core.

  # Settings
  Record.defrecord(:settings, safe: nil, spawn?: nil, task: nil, ack?: nil, sticky?: nil, timeout: nil)
  def sticky?(nil), do: false
  def sticky?(settings(sticky?: v)), do: v
  def spawn?(nil), do: false
  def spawn?(settings(spawn?: v)), do: v
  def ack?(nil), do: false
  def ack?(settings(ack?: v)), do: v
  def timeout(nil), do: nil
  def timeout(settings(timeout: v)), do: v
  def safe(nil), do: nil
  def safe(settings(safe: v)), do: v
  def task(nil), do: nil
  def task(settings(task: v)), do: v
  



 
  
  # Msg
  Record.defrecord(:s, call: nil, context: nil)
  Record.defrecord(:msg_envelope,
    identifier: nil,
    type: nil,
    recipient: nil,
    settings: nil,
    msg: nil,
  )

  def call_context(nil), do: nil
  def call_context(s(context: v)), do: v
  
  

end