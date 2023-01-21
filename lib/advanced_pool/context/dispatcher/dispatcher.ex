defmodule Noizu.AdvancedPool.Dispatcher do
  require Noizu.AdvancedPool.Message
  def __process__(Noizu.AdvancedPool.Message.ref(module: worker, identifier: identifier) = ref, settings, options) do
    pool = apply(worker, :__pool__, [])
    with {pid, _} <- :syn.lookup(pool, ref) do
      {:ok, pid}
    end
    catch e -> {:error, e}
  end

  defmacro default() do
    quote do
      defmodule Dispatcher do
        @pool Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat()
        def __pool__(), do: @pool
        
        def __process__(ref, settings, options) do
          Noizu.AdvancedPool.Dispatcher.__process__(ref, settings, options)
        end

      end
    end
  end


end