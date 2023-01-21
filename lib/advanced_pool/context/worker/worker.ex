defmodule Noizu.AdvancedPool.Worker do

  defmacro default() do
    quote do
      defmodule Worker do
  
        def __dispatcher__(recipient, hint) do
          {:ok, __MODULE__}
        end
        
      end
    end
  end

end