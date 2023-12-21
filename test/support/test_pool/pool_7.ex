#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.Support.TestPool7 do
  use Noizu.AdvancedPool
  Noizu.AdvancedPool.Server.default()
  require Noizu.AdvancedPool.Message

  def __worker__(), do: Noizu.AdvancedPool.Support.TestPool7.Worker
  def __call_settings__(), do: Noizu.AdvancedPool.Message.settings(sticky?: 1.1, timeout: 60_000)
  def test(identifier, context) do
    s_call!(identifier, :test, context)
  end
end

defmodule Noizu.AdvancedPool.Support.TestPool7.Worker do
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M
  alias Noizu.AdvancedPool.Message.Handle, as: MessageHandler
  require Logger
  defstruct [
    identifier: nil,
    test: 0.0
  ]
  use Noizu.AdvancedPool.Worker.Behaviour



  def ref_ok({:ref, __MODULE__, _} = ref), do: {:ok, ref}
  def ref_ok(ref) when is_integer(ref), do: {:ok, {:ref, __MODULE__, ref}}
  def ref_ok(%__MODULE__{identifier: id}), do: {:ok, {:ref, __MODULE__, id}}
  def ref_ok(ref), do: {:error, {:unsupported, ref}}
  
  #-----------------------
  #
  #-----------------------
  def handle_call(msg_envelope() = call, from, state) do
    MessageHandler.unpack_call(call, from, state)
  end
  def handle_call(s(call: :test, context: context), _, state) do
    test(state, context)
  end
  def handle_call(msg, from, state) do
    super(msg, from, state)
  end

  #-----------------------
  #
  #-----------------------
  def handle_cast(msg_envelope() = call, state) do
    MessageHandler.unpack_cast(call, state)
  end
  def handle_cast(msg, state) do
    super(msg, state)
  end

  #-----------------------
  #
  #-----------------------
  def handle_info(msg_envelope() = call, state) do
    MessageHandler.unpack_info(call, state)
  end
  def handle_info(msg, state) do
    super(msg, state)
  end
  
  #-----------------------
  #
  #-----------------------
  def test(state = %Noizu.AdvancedPool.Worker.State{}, _context, _options \\ nil) do
    state = state
            |>update_in([Access.key(:worker), Access.key(:test)], &(&1 + 1))
    {:reply, state.worker.test, state}
  end
  
end
