defmodule Noizu.AdvancedPool.State do
  @moduledoc """
  Represents the state of various components within the Noizu AdvancedPool system.

  The `Noizu.AdvancedPool.State` struct encapsulates the operating state of pool components such as supervisors,
  servers, and other pool-related entities. It stores key information about the status, supervisor process,
  the owning pool, any related components, and associated bookkeeping details required for operation management
  and health checks within the AdvancedPool framework.

  How it is used:

  The state struct is primarily used by internal modules of the AdvancedPool framework to maintain and transition
  the state of components during the lifecycle of the pool. For instance, changes in the state may be used to trigger
  rebalancing, supervision actions, or configuration updates.

  Who uses it:

  This struct is utilized by pool managers, supervisors, and potentially server processes that coordinate within
  the pool framework. It is crucial for the operations of the underlying OTP supervision trees that manage worker
  processes and handle fault tolerance.

  The design of this module and its state struct is tightly coupled with the AdvancedPool's architecture and is
  intended for internal use as part of the private API that underpins the framework's functionality.
  """

  @vsn 1.0
  defstruct [
    status: nil,
    supervisor: nil,
    pool: nil,
    component: nil,
    book_keeping: nil,
    vsn: @vsn
  ]
end
