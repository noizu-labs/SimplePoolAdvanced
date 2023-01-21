defmodule Noizu.AdvancedPool.NodeManager.Server do
  use GenServer
  require Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M

  defstruct [
    meta: []
  ]
  
  def start_link(context, options) do
    GenServer.start_link(__MODULE__, {context, options}, name: __MODULE__)
  end
  
  def init({_context, _options}) do
    :syn.register(Noizu.AdvancedPool.NodeManager, node(), self(), [node: node(), start: :os.system_time(:second)])
    :syn.join(Noizu.AdvancedPool.NodeManager, :managers, self(), [node: node(), start: :os.system_time(:second)])
    :syn.register(__pool__(), {:ref, __MODULE__, node()}, self(), nil)
    {:ok, %Noizu.AdvancedPool.NodeManager.Server{}}
  end

  def spec(context, options \\ nil) do
    %{
      id: __MODULE__,
      type: :worker,
      start: {__MODULE__, :start_link, [context, options]}
    }
  end

  #================================
  # Behaviour
  #================================
  def __pool__(), do: Noizu.AdvancedPool.NodeManager
  def __server__(), do: Noizu.AdvancedPool.NodeManager.Server
  def __dispatcher__(recipient, context), do: {:dynamic, Noizu.AdvancedPool.Dispatcher, [[]]}


  #================================
  # Methods
  #================================
  def health_report(state, _context) do
    {:reply, :health_report, state}
  end
  
  #================================
  # Message Handling
  #================================
  def handle_call(M.msg_envelope() = call, from, state) do
    Noizu.AdvancedPool.Message.Handle.unpack_call(call, from, state)
  end
  def handle_call(M.s(call: :health_report) = call, _, state) do
    health_report(state, M.s(call, :context))
  end
  
  def handle_cast(M.msg_envelope() = call, state) do
    Noizu.AdvancedPool.Message.Handle.unpack_cast(call, state)
  end
  
  def handle_info(M.msg_envelope() = call, state) do
    Noizu.AdvancedPool.Message.Handle.unpack_info(call, state)
  end
end

defmodule Noizu.AdvancedPool.NodeManager do
  use Supervisor
  require Noizu.AdvancedPool.Message
  alias Noizu.AdvancedPool.Message, as: M

  def spec(context, options \\ nil) do
    %{
      id: __MODULE__,
      type: :supervisor,
      start: {__MODULE__, :start_link, [context, options]}
    }
  end
  
  def start_link(context, options) do
    :syn.add_node_to_scopes([__MODULE__])
    Supervisor.start_link(__MODULE__, {context, options}, name: __MODULE__)
  end
  
  def init({context, options}) do
    [
      Noizu.AdvancedPool.NodeManager.Server.spec(context, options)
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end

  #================================
  # Behaviour
  #================================
  def __pool__(), do: __MODULE__
  def __server__(), do: Noizu.AdvancedPool.NodeManager.Server
  def __dispatcher__(recipient, context), do: {:dynamic, Noizu.AdvancedPool.Dispatcher, [[]]}
  def __cast_settings__(), do: M.settings(timeout: 5000)
  def __call_settings__(), do: M.settings(timeout: 60_000)

  #================================
  # Entry Point
  #================================
  def health_report(context) do
    Noizu.AdvancedPool.Message.Dispatch.s_call!({:ref, Noizu.AdvancedPool.NodeManager.Server, node()}, :health_report, context)
  end
  
  
end