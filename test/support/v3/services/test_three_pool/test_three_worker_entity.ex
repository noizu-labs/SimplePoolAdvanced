#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.Support.TestV3WorkerThree do
  use Noizu.AdvancedPool.ServiceWorker
  @vsn 1.0
  @sref "noizu-test-3"
  defmodule Entity do
    @pool Noizu.AdvancedPool.Support.TestV3Pool
    Noizu.AdvancedPool.ServiceWorker.service_worker_entity() do
      identifier :string
      public_field :data, %{}
    end



    def supervisor_hint(ref) do
      id = id(ref)
      cond do
        is_integer(id) -> id
        is_bitstring(id) ->
          "test_" <> ts = id
          String.to_integer(ts)
      end
    end


    #-----------------------------------------------------------------------------
    # Behaviour
    #-----------------------------------------------------------------------------
    def load(ref), do: load(ref, nil, nil)
    def load(ref, context), do: load(ref, nil, context)
    def load(ref, _options, _context) do
      %__MODULE__{
        identifier: id(ref)
      }
    end

    #-----------------------------------------------------------------------------
    # Implementation
    #-----------------------------------------------------------------------------
    def test_s_call!(this, value, _context) do
      state = put_in(this, [Access.key(:data), :s_call!], value)
      {:reply, :s_call!, state}
    end
    def test_s_call(this, value, _context), do: {:reply, :s_call, put_in(this, [Access.key(:data), :s_call], value)}
    def test_s_cast!(this, value, _context), do: {:noreply,  put_in(this, [Access.key(:data), :s_cast!], value)}
    def test_s_cast(this, value, _context) do
      updated_state = put_in(this, [Access.key(:data), :s_cast], value)
      {:noreply,  updated_state}
    end

    #-----------------------------------------------------------------------------
    # call_forwarding
    #-----------------------------------------------------------------------------

    #------------------------------------------------------------------------
    # call router
    #------------------------------------------------------------------------
    def __handle_call__({:spawn, envelope}, from, state), do: __handle_call__(envelope, from, state)
    def __handle_call__({:passive, envelope}, from, state), do: __handle_call__(envelope, from, state)
    def __handle_call__({:s, {:test_s_call!, value}, context}, _from, state), do: test_s_call!(state, value, context)
    def __handle_call__({:s, {:test_s_call, value}, context}, _from, state), do: test_s_call(state, value, context)
    def __handle_call__(call, from, state), do: super(call, from, state)


    def __handle_cast__({:spawn, envelope}, state), do: __handle_cast__(envelope, state)
    def __handle_cast__({:passive, envelope}, state), do: __handle_cast__(envelope, state)
    def __handle_cast__({:s, {:test_s_cast!, value}, context}, state), do: test_s_cast!(state, value, context)
    def __handle_cast__({:s, {:test_s_cast, value}, context}, state), do: test_s_cast(state, value, context)
    def __handle_cast__(call, state), do: super(call, state)


    #-------------------
    # id/1
    #-------------------
    def id({:ref, __MODULE__, identifier}), do: identifier
    def id("ref.noizu-test-3." <> identifier), do: identifier
    def id(%__MODULE__{} = entity), do: entity.identifier

    #-------------------
    # ref/1
    #-------------------
    def ref(identifier) when is_integer(identifier), do: {:ref, __MODULE__, identifier}
    def ref({:ref, __MODULE__, identifier}), do: {:ref, __MODULE__, identifier}
    def ref("ref.noizu-test-3." <> identifier), do: {:ref, __MODULE__, identifier}
    def ref(%__MODULE__{} = entity), do: {:ref, __MODULE__, entity.identifier}

    #-------------------
    # sref/1
    #-------------------
    def sref({:ref, __MODULE__, identifier}), do: "ref.noizu-test-3.#{identifier}"
    def sref("ref.noizu-test-3." <> identifier), do: "ref.noizu-test-3.#{identifier}"
    def sref("test_" <> _ = identifier), do: "ref.noizu-test-3.#{identifier}"
    def sref(%__MODULE__{} = entity), do: "ref.noizu-test-3.#{entity.identifier}"
    def sref(_), do: nil

    #-------------------
    # entity/2
    #-------------------
    def entity(ref, options \\ %{})
    def entity({:ref, __MODULE__, identifier}, _options), do: %__MODULE__{identifier: identifier}
    def entity("ref.noizu-test-3." <> identifier, _options), do: %__MODULE__{identifier: identifier}
    def entity(%__MODULE__{} = entity, _options), do: entity

    #-------------------
    # entity!/2
    #-------------------
    def entity!(ref, options \\ %{})
    def entity!({:ref, __MODULE__, identifier}, _options), do: %__MODULE__{identifier: identifier}
    def entity!("ref.noizu-test-3." <> identifier, _options), do: %__MODULE__{identifier: identifier}
    def entity!(%__MODULE__{} = entity, _options), do: entity


    #-------------------
    # record/2
    #-------------------
    def record(ref, options \\ %{})
    def record({:ref, __MODULE__, identifier}, _options), do: %__MODULE__{identifier: identifier}
    def record("ref.noizu-test-3." <> identifier, _options), do: %__MODULE__{identifier: identifier}
    def record(%__MODULE__{} = entity, _options), do: entity

    #-------------------
    # record!/2
    #-------------------
    def record!(ref, options \\ %{})
    def record!({:ref, __MODULE__, identifier}, _options), do: %__MODULE__{identifier: identifier}
    def record!("ref.noizu-test-3." <> identifier, _options), do: %__MODULE__{identifier: identifier}
    def record!(%__MODULE__{} = entity, _options), do: entity


    def id_ok(o) do
      r = id(o)
      r && {:ok, r} || {:error, o}
    end
    def ref_ok(o) do
      r = ref(o)
      r && {:ok, r} || {:error, o}
    end
    def sref_ok(o) do
      r = sref(o)
      r && {:ok, r} || {:error, o}
    end
    def entity_ok(o, options \\ %{}) do
      r = entity(o, options)
      r && {:ok, r} || {:error, o}
    end
    def entity_ok!(o, options \\ %{}) do
      r = entity!(o, options)
      r && {:ok, r} || {:error, o}
    end


  end

  defmodule Repo do
    Noizu.AdvancedPool.ServiceWorker.service_worker_repo() do

    end
  end
end # end defmacro

defimpl Noizu.ERP, for: Noizu.AdvancedPool.Support.TestV3WorkerThree.Entity do
  def id(obj) do
    obj.identifier
  end # end sref/1

  def ref(obj) do
    {:ref, Noizu.AdvancedPool.Support.TestV3WorkerThree.Entity, obj.identifier}
  end # end ref/1

  def sref(obj) do
    "ref.noizu-test-3.#{obj.identifier}"
  end # end sref/1

  def record(obj, _options \\ nil) do
    obj
  end # end record/2

  def record!(obj, _options \\ nil) do
    obj
  end # end record/2

  def entity(obj, _options \\ nil) do
    obj
  end # end entity/2

  def entity!(obj, _options \\ nil) do
    obj
  end # end defimpl EntityReferenceProtocol, for: Tuple


  def id_ok(o) do
    r = ref(o)
    r && {:ok, r} || {:error, o}
  end
  def ref_ok(o) do
    r = ref(o)
    r && {:ok, r} || {:error, o}
  end
  def sref_ok(o) do
    r = sref(o)
    r && {:ok, r} || {:error, o}
  end
  def entity_ok(o, options \\ %{}) do
    r = entity(o, options)
    r && {:ok, r} || {:error, o}
  end
  def entity_ok!(o, options \\ %{}) do
    r = entity!(o, options)
    r && {:ok, r} || {:error, o}
  end

end