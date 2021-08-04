#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SimplePool.DispatchRepoBehaviour do
  use Amnesia


  defmacro __using__(options) do
    # @todo expand options options = Macro.expand(options, __ENV__)
    dispatch_table = options[:dispatch_table]

    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @dispatch_table unquote(dispatch_table)
      use Amnesia
      import unquote(__MODULE__)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def schema_online?() do
        case Amnesia.Table.wait([@dispatch_table], 5) do
          :ok -> true
          _ -> false
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def prepare_lock(options, force \\ false) do
        Noizu.SimplePool.DispatchRepoBehaviourDefault.prepare_lock(options, force)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def new(ref, context, options \\ %{}) do
        Noizu.SimplePool.DispatchRepoBehaviourDefault.new(__MODULE__, ref, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def obtain_lock!(ref, context, options \\ %{lock: %{}}) do
        Noizu.SimplePool.DispatchRepoBehaviourDefault.obtain_lock!(__MODULE__, ref, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def release_lock!(ref, context, options \\ %{}) do
        Noizu.SimplePool.DispatchRepoBehaviourDefault.release_lock!(__MODULE__, ref, context, options)
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def workers!(host, service_entity, _context, options \\ %{}) do
        if schema_online?() do
          v = @dispatch_table.match!([identifier: {:ref, service_entity, :_}, server: host])
              |> Amnesia.Selection.values
          {:ack, v}
        else
          {:nack, []}
        end
      end

      #-------------------------
      #
      #-------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def get!(id, _context, _options \\ %{}) do
        if schema_online?() do
          id
          |> @dispatch_table.read!()
          |> Noizu.ERP.entity()
        else
          nil
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def update!(%Noizu.SimplePool.DispatchEntity{} = entity, _context, options \\ %{}) do
        if schema_online?() do
          %@dispatch_table{identifier: entity.identifier, server: entity.server, entity: entity}
          |> @dispatch_table.write!()
          |> Noizu.ERP.entity()
        else
          nil
        end

      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def create!(%Noizu.SimplePool.DispatchEntity{} = entity, _context, options \\ %{}) do
        if schema_online?() do
          %@dispatch_table{identifier: entity.identifier, server: entity.server, entity: entity}
          |> @dispatch_table.write!()
          |> Noizu.ERP.entity()
        else
          nil
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def delete!(entity, _context, _options \\ %{}) do
        if schema_online?() do
          @dispatch_table.delete!(entity.identifier)
        end
        entity
      end

      #-------------------------
      #
      #-------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def get(id, _context, _options \\ %{}) do
        if schema_online?() do
          id
          |> @dispatch_table.read()
          |> Noizu.ERP.entity()
        else
          nil
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def update(%Noizu.SimplePool.DispatchEntity{} = entity, _context, options \\ %{}) do
        if schema_online?() do
          %@dispatch_table{identifier: entity.identifier, server: entity.server, entity: entity}
          |> @dispatch_table.write()
          |> Noizu.ERP.entity()
        else
          nil
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def create(%Noizu.SimplePool.DispatchEntity{} = entity, _context, options \\ %{}) do
        if schema_online?() do
          %@dispatch_table{identifier: entity.identifier, server: entity.server, entity: entity}
          |> @dispatch_table.write()
          |> Noizu.ERP.entity()
        else
          nil
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def delete(entity, _context, _options \\ %{}) do
        if schema_online?() do
          @dispatch_table.delete(entity.identifier)
          entity
        else
          nil
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      defimpl Noizu.ERP, for: @dispatch_table do
        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def id(obj) do
          obj.identifier
        end # end sref/1

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def ref(obj) do
          {:ref, Noizu.SimplePool.DispatchEntity, obj.identifier}
        end # end ref/1

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def sref(obj) do
          "ref.noizu-dispatch.[#{Noizu.ERP.sref(obj.identifier)}]"
        end # end sref/1

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def record(obj, _options \\ nil) do
          obj
        end # end record/2

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def record!(obj, _options \\ nil) do
          obj
        end # end record/2

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def entity(obj, _options \\ nil) do
          obj.entity
        end # end entity/2

        @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
        def entity!(obj, _options \\ nil) do
          obj.entity
        end # end defimpl EntityReferenceProtocol, for: Tuple
      end # end defimpl

    @file __ENV__.file
    end # end quote
  end # end __suing__
end # end module
