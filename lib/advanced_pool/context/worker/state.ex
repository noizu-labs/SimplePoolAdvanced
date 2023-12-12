defmodule Noizu.AdvancedPool.Worker.State do
  @moduledoc """
  Defines a struct representing the state of a worker within the `Noizu.AdvancedPool`.

  `Worker.State` encapsulates essential information about a worker process, such as its unique identifier,
  handler module, current status, and any auxiliary data required for its operation. This defined state is used
  to manage the lifecycle of the worker, track its performance and behavior, and facilitate message routing and handling.

  The version (`vsn`) field ensures that the state struct can evolve over time while maintaining compatibility
  with different versions of the worker processes.
  """

  @vsn 1.0
  defstruct [
    identifier: nil,
    handler: nil,
    status: nil,
    status_info: nil,
    worker: nil,
    aux: nil,
    book_keeping: nil,
    vsn: @vsn
  ]
end
