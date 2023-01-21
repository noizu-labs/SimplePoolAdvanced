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
  Record.defrecord(:node, node: nil)
  Record.defrecord(:node_manager, recipient: nil)
  Record.defrecord(:ref, module: nil, identifier: nil) # move to elixir core.

  # Settings
  Record.defrecord(:settings, safe: nil, spawn?: nil, task: nil, ack?: nil, timeout: nil)

  # Msg
  Record.defrecord(:s, call: nil, context: nil)
  Record.defrecord(:msg_envelope,
    identifier: nil,
    type: nil,
    recipient: nil,
    settings: nil,
    msg: nil,
  )

end