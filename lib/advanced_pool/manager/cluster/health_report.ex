defmodule Noizu.AdvancedPool.ClusterManager.HealthReport do
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



  defmodule Formatter do
    def format(%Noizu.AdvancedPool.ClusterManager.HealthReport{report: report}, options \\ nil) do
      Enum.map(report, fn {node, node_report} ->
        if is_map(node_report) and is_map(node_report.report) do
          Enum.map(node_report.report, fn {pool, pool_report} ->
            format_pool_data(node, pool, pool_report)
          end)
        else


          %{
            node: node,
            pool: :error,
            workers: :error,
            health: :error,
            worker_supervisors: :error,
            error: node_report
          }

        end
      end)
      |> List.flatten()
      |> tabulate(options)
    end

    defp format_pool_data(node, pool, pool_report) when is_map(pool_report) do
      %{
        node: node,
        pool: pool,
        workers: pool_report.workers,
        health: pool_report.health,
        worker_supervisors: pool_report.worker_supervisors
      }
    end
    defp format_pool_data(node, pool, pool_report) do
      %{
        node: node,
        pool: pool,
        workers: :error,
        health: :error,
        worker_supervisors: :error,
        error: pool_report
      }
    end

    defp tabulate(data, options) do

      data
      |> Enum.group_by(& &1.pool)
      |> Enum.map(fn {pool, rows} ->
        open = "\n\n** #{pool} **:\n"

        simple = Enum.map(rows,
          fn
            x = %{node: n, pool: p, workers: w, health: h, worker_supervisors: ws}  ->
              {total,target} = with %{total: total, target: target} <- w do
                {total, target}
              else
                _ -> {:error, :error}
              end
              Enum.join([n, inspect(total), inspect(target), inspect( is_float(h) && Float.round(h, 3) || h)], "\t\t")
              _ -> nil
          end) |> Enum.reject(&is_nil/1)

        run = Enum.map(rows, fn
          %{node: n} -> String.length("#{inspect n}")
          _ -> nil
        end) |> Enum.reject(&is_nil/1) |> Enum.max()
        headers = ["Node" <> String.duplicate(" ", run - 4), "Workers", "Target", "Health"] |> Enum.join("\t\t")


        unless options[:verbose] do
          ([open, headers | simple] ) |> Enum.join("\n")
        else
          mid = "\n---------\nDetails:\n"

          details = Enum.map(rows,
                      fn
                        x = %{node: n, worker_supervisors: ws}  ->
                          e = with %{extended: e} <- ws do
                            e
                          else
                            _ -> :none
                          end
                          error = x[:error]

                          """
                          #{n}:
                            extended: #{inspect e, pretty: true}
                            #{error && inspect(error) <> "\n" || ""}
                          """
                        _ -> nil
                      end) |> Enum.reject(&is_nil/1)

          ([open, headers | simple] ++ [mid | details]) |> Enum.join("\n")
        end


      end) |> Enum.join("\n")

    end
  end



end
