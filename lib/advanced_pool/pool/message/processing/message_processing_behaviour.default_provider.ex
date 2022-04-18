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
      def __delegate_call_handler(call, from, state), do: Default.__delegate_call_handler(__MODULE__, call, from, state)
      def __delegate_cast_handler(call, state), do: Default.__delegate_cast_handler(__MODULE__, call, state)
      def __delegate_info_handler(call, state), do: Default.__delegate_info_handler(__MODULE__, call, state)

      #----------------
      # call routing
      #----------------
      def handle_call(msg, from, state), do: Default.__handle_call(__MODULE__, msg, from, state)
      def call_router_user(_msg, _from, _state), do: nil
      def call_router_internal(_msg, _from, _state), do: nil
      def call_router_catchall(msg, from, state), do: Default.__call_router_catchall(__MODULE__, msg, from, state)
      def __call_handler(msg, from, state) do
        call_router_user(msg, from, state) || call_router_internal(msg, from, state) || call_router_catchall(msg, from, state)
      end

      #----------------
      # cast routing
      #----------------
      def handle_cast(msg, state), do: Default.__handle_cast(__MODULE__, msg, state)
      def cast_router_user(_msg, _state), do: nil
      def cast_router_internal(_msg, _state), do: nil
      def cast_router_catchall(msg, state), do: Default.__cast_router_catchall(__MODULE__, msg, state)
      def __cast_handler(msg, state) do
        cast_router_user(msg, state) || cast_router_internal(msg, state) || cast_router_catchall(msg, state)
      end

      #----------------
      # info routing
      #----------------
      def handle_info(msg, state), do: Default.__handle_info(__MODULE__, msg, state)
      def info_router_user(_msg, _state), do: nil
      def info_router_internal(_msg, _state), do: nil
      def info_router_catchall(msg, state), do: Default.__info_router_catchall(__MODULE__, msg, state)
      def __info_handler(msg, state) do
        info_router_user(msg, state) || info_router_internal(msg, state) || info_router_catchall(msg, state)
      end

      defdelegate as_cast(t), to: Default
      defdelegate as_info(t), to: Default, as: :as_cast

      #===============================================================================================================
      # Overridable
      #===============================================================================================================
      defoverridable [
        # inner routing
        __delegate_call_handler: 3,
        __delegate_cast_handler: 2,
        __delegate_info_handler: 2,

        # call routing
        call_router_user: 3,
        call_router_internal: 3,
        call_router_catchall: 3,
        __call_handler: 3,

        # cast routing
        cast_router_user: 2,
        cast_router_internal: 2,
        cast_router_catchall: 2,
        __cast_handler: 2,

        # info routing
        info_router_user: 2,
        info_router_internal: 2,
        info_router_catchall: 2,
        __info_handler: 2,

        as_cast: 1,
        as_info: 1,
      ]
    end
  end
end
