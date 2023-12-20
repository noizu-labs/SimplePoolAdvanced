defmodule Noizu.AdvancedPool.NodeManager.HealthReport do
  @moduledoc """

  """

  @vsn 1.0
  defstruct [
    worker: nil, # task pid
    subscribers: [], # receiver pid to send completion update to
    status: nil, # :finished, :preparing, :error
    started_at: nil,
    finished_at: nil,
    report: nil,
    book_keeping: nil,
    vsn: @vsn
  ]

  def processing?(nil), do: false
  def processing?(%{status: :ready}), do: false
  def processing?(%{status: :error}), do: false
  def processing?(%{status: :processing}) do
    # verify task is active
    true
  end



end
