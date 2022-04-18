#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.MessageProcessingBehaviour.DefaultProvider do
  defmacro __using__(_options) do
    quote do
      require Logger
      @module __MODULE__
      @behaviour Noizu.AdvancedPool.MessageProcessingBehaviour
      alias Noizu.AdvancedPool.MessageProcessingBehaviour.Default
      #===============================================================================================================
      # Call routing
      #===============================================================================================================

      #---------------
      #  delegated handlers - pass calls onto to inner state.
      #---------------
      def __delegate_handle_call__(call, from, state), do: Default.__delegate_handle_call__(__MODULE__, call, from, state)
      def __delegate_handle_cast__(call, state), do: Default.__delegate_handle_cast__(__MODULE__, call, state)
      def __delegate_handle_info__(call, state), do: Default.__delegate_handle_info__(__MODULE__, call, state)

      #----------------
      # call routing
      #----------------
      def handle_call(msg, from, state), do: Default.__handle_call__(__MODULE__, msg, from, state)
      def __handle_call__(msg, from, state) do
        Default.__call_router_catchall__(__MODULE__, msg, from, state)
      end

      #----------------
      # cast routing
      #----------------
      def handle_cast(msg, state), do: Default.__handle_cast__(__MODULE__, msg, state)
      def __handle_cast__(msg, state) do
        Default.__cast_router_catchall__(__MODULE__, msg, state)
      end

      #----------------
      # info routing
      #----------------
      def handle_info(msg, state), do: Default.__handle_info__(__MODULE__, msg, state)
      def __handle_info__(msg, state) do
        Default.__info_router_catchall__(__MODULE__, msg, state)
      end

      defdelegate as_cast(t), to: Default
      defdelegate as_info(t), to: Default, as: :as_cast

      #===============================================================================================================
      # Overridable
      #===============================================================================================================
      defoverridable [
        # inner routing
        __delegate_handle_call__: 3,
        __delegate_handle_cast__: 2,
        __delegate_handle_info__: 2,

        # call routing
        __handle_call__: 3,

        # cast routing
        __handle_cast__: 2,

        # info routing
        __handle_info__: 2,
      ]
    end
  end
end
