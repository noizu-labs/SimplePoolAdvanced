defmodule Noizu.SimplePoolAdvanced.V3.Service.DomainObject do

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
    q = Noizu.AdvancedScaffolding.Internal.DomainObject.Entity.__noizu_entity__(__CALLER__, options, block)
    quote do
      unquote(q)
      pool = Module.get_attribute(__MODULE__, :pool) || Module.get_attribute(@__nzdo__base, :pool) || throw "#{__MODULE__} requires @pool attribute"
      use Noizu.SimplePoolAdvanced.V3.InnerStateBehaviour,
          pool: pool
    end
  end

  #--------------------------------------------
  # service_worker_repo
  #--------------------------------------------
  defmacro service_worker_repo(options \\ [], [do: block]) do
    options = Macro.expand(options, __ENV__)
    Noizu.AdvancedScaffolding.Internal.DomainObject.Repo.__noizu_repo__(__CALLER__, options, block)
  end


end
