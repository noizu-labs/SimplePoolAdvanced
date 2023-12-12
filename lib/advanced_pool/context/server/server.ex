defmodule Noizu.AdvancedPool.Server do
  @moduledoc """
  Provides a macro for defining a default server within the `Noizu.AdvancedPool` framework.
  This macro is used to generate a new server module that encapsulates the common server functionality and
  configuration required for interacting with the pool and managing the message flow to and from worker processes.

  The macro facilitates a concise and consistent way to declare a server for managing a subset of the pool's workers,
  abstracting away common boilerplate code and embedding standard behaviors associated with a pool's server.
  """
  defmacro default() do
    quote do
      defmodule Server do
        @pool Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat()
              #|> IO.inspect(label: :server)

        @doc """
        Returns the pool module that this server is a part of, allowing for introspection or configuration retrieval.
        """
        def __pool__(), do: @pool


        @doc """
        Retrieves the configuration for the server from the associated pool module's configuration.
        This configuration can dictate various operational parameters and settings of the server.
        """
        def config(), do: apply(__pool__(), :config, [])


        @doc """
        Generates the specification for starting this server, including its module, function, and arguments,
        along with its context and any additional options. This specification is used by the supervisory process
        when initializing this server within the pool's OTP structure.
        """
        def server_spec(context, options \\ nil) do
          Noizu.AdvancedPool.Server.DefaultServer.server_spec(__MODULE__, context, options)
        end


        @doc """
        Provides a dispatching endpoint for messages intended for this server.
        It enables the routing of messages to appropriate handlers within the server, with the facility for adding
        custom logic based on the recipient and provided hints.
        """
        def __dispatcher__(recipient, hint) do
          {:ok, __MODULE__}
        end
   
        
        
        
      end
    end
  end
   
   
end
