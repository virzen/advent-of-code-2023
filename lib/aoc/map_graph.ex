defmodule AOC.MapGraph do
  @moduledoc """
  A graph in format
  %{
    key => key[]
  }
  """

  defp traverse_dfs_step(graph, visited, vertex) do
  end

  defp traverse_bfs_step(graph, visited, vertex) do
  end

  # stop is a boolean function deciding whether to stop, takes visited and
  # current vertex
  def walk(graph, start, stop, method \\ :bfs) do
  end

  # uses DFS
  defp find_all_paths_step(graph, stop, path, current) do
    updated_path =
      [current | path]

    if stop.(current) do
      [updated_path]
    else
      adjacent = get_adjacent(graph, current)

      to_visit =
        adjacent
        |> Enum.reject(&Enum.member?(path, &1))

      if Enum.empty?(to_visit) do
        [nil]
      else
        to_visit
        |> Enum.flat_map(fn v_to_visit ->
          find_all_paths_step(graph, stop, updated_path, v_to_visit)
        end)
        |> Enum.reject(&is_nil/1)
      end
    end
  end

  defp find_first_path_step(graph, stop, path, current) do
    updated_path =
      [current | path]

    if stop.(current) do
      updated_path
    else
      adjacent = get_adjacent(graph, current)

      to_visit =
        adjacent
        |> Enum.reject(&Enum.member?(path, &1))

      if Enum.empty?(to_visit) do
        nil
      else
        to_visit
        |> Enum.reduce_while(nil, fn v_to_visit, _acc ->
          maybe_path = find_first_path_step(graph, stop, updated_path, v_to_visit)

          case maybe_path do
            nil -> {:cont, nil}
            path -> {:halt, path}
          end
        end)
      end
    end
  end

  # naively walk
  def find_all_paths(graph, from, to) do
    stop = fn v -> v == to end

    graph
    |> find_all_paths_step(stop, [], from)
    |> Enum.map(&Enum.reverse/1)
  end

  def find_first_path_dfs(graph, from, to) do
    stop = fn v -> v == to end

    graph
    |> find_first_path_step(stop, [], from)
    |> Enum.reverse()
  end

  def find_shortest_path_naive(graph, from, to) do
    graph
    |> find_all_paths(from, to)
    |> Enum.sort_by(&length/1, :asc)
    |> List.first()
  end

  # dijkstra?
  def find_shortest_path(graph, from, to) do
  end

  # A*
  @doc """
  Performs A* start search of shortest path from a to b, using heuristic.
  Heuristic takes one argument, key of a vertex and is supposed to return
  estimate of the distance to the destination, lower value means closer.
  """
  def find_shortest_path(graph, a, b, heuristic) do
    # just DFS + sort by heuristic? lower values first
    stop = fn vertex -> vertex == b end

    graph
    |> find_shortest_path_a_star_step(stop, [], heuristic, a)
    |> Enum.reverse()

    # alternatively hold more vertices and go where the sum of heuristic is
    # lowest, meaning you might jump
  end

  defp find_shortest_path_a_star_step(graph, stop, path, heuristic, vertex) do
    updated_path = [vertex | path]

    if stop.(vertex) do
      updated_path
    else
      to_visit =
        graph
        |> get_adjacent(vertex)
        |> Enum.reject(&Enum.member?(path, &1))
        |> Enum.sort_by(heuristic, :asc)

      # to_visit
      # |> Enum.map(fn v ->
      #   {v, heuristic.(v)}
      # end)
      # |> IO.inspect()

      to_visit
      |> Enum.reduce_while(nil, fn v, _acc ->
        maybe_path = find_shortest_path_a_star_step(graph, stop, updated_path, heuristic, v)

        case maybe_path do
          nil -> {:cont, nil}
          path -> {:halt, path}
        end
      end)
    end
  end

  def get_adjacent(graph, key) do
    Map.get(graph, key)
  end
end
