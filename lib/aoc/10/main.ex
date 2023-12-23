defmodule MapMatrix do
  @moduledoc """
  Creates map-based matrix representation, in the form of
  %{
    {x, y} => value
  }
  Assumes the size of the last row to be the width of the matrix.

  TODO: use struct to pattern match on this exact structure instead of
  accepting any map, like MapSet.
  """

  @doc """
  Expects a new-line-delimited string with lines of equal size.
  """
  def from_string(string) do
    lines = string |> String.trim() |> String.split("\n")
    width = String.length(List.first(lines))

    {matrix, height} =
      lines
      |> Enum.reduce({%{}, 0}, fn line, {matrix, y} ->
        # might blow up for some future utf-encoded strings
        elems = String.codepoints(line)
        width = length(elems)

        map =
          elems
          |> Enum.zip(0..(width - 1))
          |> Enum.map(fn {val, x} ->
            {{x, y}, val}
          end)
          |> Map.new()

        {
          Map.merge(matrix, map),
          y + 1
        }
      end)

    Map.merge(matrix, %{width: width, height: height})
  end

  def size(matrix) do
    {matrix.width, matrix.height}
  end

  def at(matrix, {x, y}) do
    Map.get(matrix, {x, y})
  end

  def directions() do
    [:top, :right, :bottom, :left]
  end

  # coords could be it's own DS and module
  def coords_from({x, y}, direction) do
    case direction do
      :top -> {x, y - 1}
      :right -> {x + 1, y}
      :bottom -> {x, y + 1}
      :left -> {x - 1, y}
    end
  end

  def map(matrix, f) do
    {width, height} = size(matrix)

    new_cells =
      for x <- 0..(width - 1), y <- 0..(height - 1) do
        coords = {x, y}
        {coords, f.(at(matrix, coords), coords)}
      end
      |> Map.new()

    Map.merge(matrix, new_cells)
  end

  def find_coords(matrix, f) do
    {width, height} = size(matrix)

    all_coords =
      for x <- 0..(width - 1), y <- 0..(height - 1) do
        {x, y}
      end

    Enum.reduce_while(all_coords, nil, fn coords, _acc ->
      val = at(matrix, coords)

      if f.(val) do
        {:halt, coords}
      else
        {:cont, nil}
      end
    end)
  end
end

defmodule MapGraph do
  @moduledoc """
  A graph in format
  %{
    source => [...destinations]
  }
  """

  # here protocols maybe so MapGraph doesn't have to have MapMatrix as dependency?
  # def from_matrix(matrix) do
  #   {width, height} = MapMatrix.size(matrix)
  # end

  def get_adjacent(graph, key) do
    Map.get(graph, key)
  end
end

defmodule AOC.D10.PipeLabirynth do
  @start "S"
  @top_entries ["|", "L", "J"]
  @bottom_entries ["|", "F", "7"]
  @left_entries ["-", "7", "J"]
  @right_entries ["-", "F", "L"]

  @entries %{
    "|" => [:top, :bottom],
    "-" => [:left, :right],
    "L" => [:top, :right],
    "7" => [:left, :bottom],
    "F" => [:right, :bottom],
    "J" => [:top, :left],
    "S" => [:top, :right, :bottom, :left]
  }

  @opposite_entries %{
    :left => :right,
    :top => :bottom,
    :right => :left,
    :bottom => :top
  }

  def entries() do
    [:top, :right, :bottom, :left]
  end

  def opposite_direction(direction) do
    Map.get(@opposite_entries, direction)
  end

  def entries_of(pipe) do
    Map.get(@entries, pipe, [])
  end

  def has_entry(pipe, direction) do
    IO.puts("#{pipe}, #{direction}")
    Enum.member?(Map.get(@entries, pipe) || [], direction)
  end

  def has_bottom_entry(pipe) do
    Enum.member?(@bottom_entries, pipe)
  end

  def has_left_entry(pipe) do
    Enum.member?(@left_entries, pipe)
  end

  def has_right_entry(pipe) do
    Enum.member?(@right_entries, pipe)
  end

  def has_top_entry?(pipe) do
    Enum.member?(@top_entries, pipe)
  end

  def is_start?(pipe) do
    pipe == @start
  end
end

defmodule AOC.D10 do
  alias AOC.D10.PipeLabirynth, as: PL

  def run_1() do
    matrix =
      File.read!("lib/aoc/10/input")
      |> MapMatrix.from_string()

    start_coords = MapMatrix.find_coords(matrix, &PL.is_start?/1) |> IO.inspect()

    matrix
    |> matrix_to_graph()
    |> IO.inspect()
    |> find_loop(start_coords)
    |> IO.inspect()
    |> length()
    |> Kernel.-(1)
    |> Kernel./(2)
  end

  def matrix_to_graph(matrix) do
    matrix
    |> MapMatrix.map(fn val, {x, y} ->
      exits = PL.entries_of(val)

      exits
      |> Enum.map(fn direction ->
        coords = MapMatrix.coords_from({x, y}, direction)
        val = MapMatrix.at(matrix, coords)

        cond do
          # value out of bound of the matrix
          is_nil(val) ->
            nil

          PL.has_entry(val, PL.opposite_direction(direction)) ->
            coords

          true ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    end)
  end

  def find_loop(graph, start) do
    find_loop_step(graph, [], start, start)
  end

  # this is DFS, with stop condition hardcoded
  # TODO: move to MapGraph
  defp find_loop_step(graph, path, finish, vertex) do
    adjacent = MapGraph.get_adjacent(graph, vertex)

    IO.puts("#{inspect(vertex)} #{inspect(adjacent)}")

    prev_vertex = List.first(path)
    # reverse later
    new_path = [vertex | path]

    Enum.reduce_while(adjacent, nil, fn coords, _ ->
      cond do
        coords == prev_vertex ->
          {:cont, nil}

        coords == finish ->
          {:halt, [coords | new_path] |> Enum.reverse()}

        true ->
          path = find_loop_step(graph, new_path, finish, coords)

          if is_nil(path) do
            {:cont, nil}
          else
            {:halt, path}
          end
      end
    end)
  end
end
