defmodule Noizu.AdvancedPool.WorkerSupervisor do

  defmacro default() do
    quote do
      defmodule WorkerSupervisor do
  
        def __dispatcher__(recipient, hint) do
          {:ok, __MODULE__}
        end
        
      end
    end
  end

end