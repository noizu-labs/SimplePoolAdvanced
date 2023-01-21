defmodule Noizu.AdvancedPool.Worker.Behaviour do
  @type worker :: any
  @type context :: term
  @type options :: term
  @type info :: atom | term
  
  @callback status(worker) :: term
  @callback status_details(worker) :: term
  @callback migrate(worker, node, context, options) :: term
  @callback persist(worker, context, options) :: term
  @callback load(worker, context, options) :: term
  @callback reload(worker, context, options) :: term
  @callback kill!(worker, context, options) :: term
  @callback hibernate(worker, context, options) :: term
  @callback fetch(worker, info, context, options) :: term
  @callback ping(worker, context, options) :: term
end