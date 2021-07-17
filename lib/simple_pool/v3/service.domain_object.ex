defmodule Noizu.SimplePool.V3.Service.DomainObject do

  defmacro __using__(options \\ nil) do
    options = Macro.expand(options, __ENV__)
    quote do
      use Noizu.DomainObject, unquote(options)
    end
  end

  #--------------------------------------------
  # service_worker_entity
  #--------------------------------------------
  defmacro service_worker_entity(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    q =  Noizu.ElixirScaffolding.V3.Meta.DomainObject.Entity.__noizu_entity__(__CALLER__, options, block)
    quote do
      unquote(q)

      pool = Module.get_attribute(__MODULE__, :pool) || Module.get_attribute(@__nzdo__base, :pool) || throw "#{__MODULE__} requires @pool attribute"
      use Noizu.SimplePool.V2.InnerStateBehaviour,
          pool: pool

    end
  end

  #--------------------------------------------
  # service_worker_repo
  #--------------------------------------------
  defmacro service_worker_repo(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.ElixirScaffolding.V3.Meta.DomainObject.Repo.__noizu_repo__(__CALLER__, options, block)
  end


end
