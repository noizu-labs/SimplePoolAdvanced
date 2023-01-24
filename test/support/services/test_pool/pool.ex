#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2023 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.Support.TestPool do
  use Noizu.AdvancedPool
  Noizu.AdvancedPool.Server.default()
  
  def __worker__(), do: Noizu.AdvancedPool.Support.TestPool.Worker
  
  def test(identifier, context) do
    with {:ok, link} <- apply(__worker__(), :recipient, [identifier]) do
      Noizu.AdvancedPool.Message.Dispatch.s_call!(link, :test, context)
    end
  end
  
  
  
end

defmodule Noizu.AdvancedPool.Support.TestPool.Worker do
  require Noizu.AdvancedPool.Message
  import Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M
  alias Noizu.AdvancedPool.Message.Handle, as: MessageHandler
  
  
  defstruct [
    identifier: nil,
    test: 0
  ]

  def recipient(M.link(recipient: M.ref(module: __MODULE__)) = link ), do: {:ok, link}
  def recipient(ref), do: ref_ok(ref)
  

  def ref_ok({:ref, __MODULE__, _} = ref), do: {:ok, ref}
  def ref_ok(ref) when is_integer(ref), do: {:ok, {:ref, __MODULE__, ref}}
  def ref_ok(%__MODULE__{identifier: id}), do: {:ok, {:ref, __MODULE__, id}}
  def ref_ok(ref), do: {:error, {:unsupported, ref}}
  
  def __pool__(), do: Noizu.AdvancedPool.Support.TestPool
  def __dispatcher__(), do: Noizu.AdvancedPool.Support.TestPool.__dispatcher__()
  def __registry__(), do: Noizu.AdvancedPool.Support.TestPool.__registry__()
  
  
  def init({:ref, __MODULE__, identifier}, args, context) do
    %__MODULE__{
      identifier: identifier
    }
  end


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
    {:reply, :unhandled, state}
  end

  #-----------------------
  #
  #-----------------------
  def handle_cst(msg_envelope() = call, state) do
    MessageHandler.unpack_cast(call, state)
  end
  def handle_cast(msg, state) do
    {:noreply, state}
  end

  #-----------------------
  #
  #-----------------------
  def handle_info(msg_envelope() = call, state) do
    MessageHandler.unpack_info(call, state)
  end
  def handle_info(msg, state) do
    {:noreply, state}
  end
  
  #-----------------------
  #
  #-----------------------
  def test(state = %Noizu.AdvancedPool.Worker.State{}, context, options \\ nil) do
    state = state
            |>update_in([Access.key(:worker), Access.key(:test)], &(&1 + 1))
    {:reply, state.worker.test, state}
  end
  
end