defmodule Noizu.AdvancedPool.PoolSupervisor do
  
  defmacro default() do
    quote do
      defmodule PoolSupervisor do
        
        def __dispatcher__(recipient, hint) do
          {:ok, __MODULE__}
        end

      end
    end
  end
   
   
end