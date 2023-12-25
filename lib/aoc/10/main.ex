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
    {width, height} = size(matrix)

    if x >= width or x < 0 or y >= height or y < 0 do
      :out_of_bounds
    else
      Map.get(matrix, {x, y})
    end
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

  @doc """
  Receives arguments val, {x, y}
  """
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

  def get_row(matrix, y) do
    {width, _} = size(matrix)

    for x <- 0..(width - 1) do
      {x, y}
    end
    |> Enum.map(&at(matrix, &1))
  end

  def to_string(matrix) do
    {_, height} = size(matrix)

    0..(height - 1)
    |> Enum.map(fn row_num ->
      matrix
      |> get_row(row_num)
      |> Enum.join("")
    end)
    |> Enum.join("\n")
  end

  def rows(matrix) do
    {_, height} = size(matrix)

    for y <- 0..(height - 1) do
      matrix
      |> get_row(y)
    end
  end

  def intersperse(matrix, separator) do
    {width, height} = size(matrix)
    new_width = width * 2 - 1

    interspered_row = Stream.cycle([separator]) |> Enum.take(new_width)

    new_matrix =
      matrix
      |> rows()
      |> Enum.map(&Enum.intersperse(&1, separator))
      |> Enum.intersperse(interspered_row)
      # this sucks, replace with from_nested_lists/1
      |> Enum.map(&Enum.join(&1, ""))
      |> Enum.join("\n")
      |> MapMatrix.from_string()

    Map.merge(new_matrix, %{width: new_width, height: height * 2 - 1})
  end

  @doc """
  Opposite of intersperse/2, removes every second row and every second element.
  """
  def unintersperse(matrix) do
    {width, height} = size(matrix)

    for x <- 0..(width - 1), y <- 0..(height - 1), rem(x, 2) == 0 and rem(y, 2) == 0 do
      {x, y}
    end
    |> Enum.map(fn {x, y} = coords ->
      {{div(x, 2), div(y, 2)}, MapMatrix.at(matrix, coords)}
    end)
    |> Map.new()
    |> Map.merge(%{
      width: ceil(width / 2),
      height: ceil(height / 2)
    })
  end

  def get_convolution_matrix(matrix, coords) do
    {x, y} = coords

    [
      {x - 1, y - 1},
      {x, y - 1},
      {x + 1, y - 1},
      {x - 1, y},
      # {x, y},
      {x + 1, y},
      {x - 1, y + 1},
      {x, y + 1},
      {x + 1, y + 1}
    ]
    |> Enum.map(&{&1, MapMatrix.at(matrix, &1)})
    |> Map.new()
    |> Map.merge(%{width: 3, height: 3})
  end

  @doc """
  Receives val, {x, y}, %MapMatrix{}. Last argument is a MapMatrix of items around val, excluding val.

  Doesn't make sense to leave old coords, even though sometimes it might be useful. Should be 0, 0, 1, 0 etc.
  """
  def map_convolutional(matrix, f) do
    {width, height} = size(matrix)

    new_cells =
      for x <- 0..(width - 1), y <- 0..(height - 1) do
        coords = {x, y}

        {coords, f.(at(matrix, coords), coords, get_convolution_matrix(matrix, coords))}
      end
      |> Map.new()

    Map.merge(matrix, new_cells)
  end

  def any?(matrix, f) do
    rows(matrix) |> List.flatten() |> Enum.any?(f)
  end

  def coords_moved_by({ox, oy} = _original, {dx, dy} = _delta) do
    {ox + dx, oy + dy}
  end

  def to_full_graph_of_coords(matrix) do
    matrix
    |> MapMatrix.map(fn _val, coords ->
      matrix
      |> get_convolution_matrix(coords)
      |> Map.drop([:width, :height])
      |> Enum.filter(fn {key, val} -> val != :out_of_bounds end)
      |> Map.new()
      |> Map.keys()
    end)
    |> Map.drop([:height, :width])
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

  def is_pipe?(maybe_pipe) do
    Enum.member?(Map.keys(@entries), maybe_pipe)
  end
end

defmodule AOC.D10 do
  alias AOC.D10.PipeLabirynth, as: PL

  def run_1() do
    matrix =
      File.read!("lib/aoc/10/input")
      |> MapMatrix.from_string()

    start_coords = MapMatrix.find_coords(matrix, &PL.is_start?/1)

    matrix
    |> matrix_to_pipe_graph()
    |> find_loop(start_coords)
    |> length()
    |> Kernel.-(1)
    |> Kernel./(2)
  end

  def run_2() do
    dir_path = "lib/aoc/10/"
    input_file = "input"

    IO.puts("Reading file...")

    matrix =
      File.read!(dir_path <> input_file)
      |> MapMatrix.from_string()

    IO.puts(MapMatrix.to_string(matrix))

    IO.puts("Calculating start coords...")
    start_coords = MapMatrix.find_coords(matrix, &PL.is_start?/1) |> IO.inspect()

    IO.puts("Calculating loop path...")

    path =
      matrix
      |> matrix_to_pipe_graph()
      |> find_loop(start_coords)
      |> IO.inspect()

    IO.puts("Calculating interspersed version of input...")

    interspersed =
      matrix
      |> MapMatrix.intersperse(".")

    interspersed
    |> MapMatrix.to_string()
    |> then(&File.write!(dir_path <> input_file <> "-interspersed", &1))

    IO.puts("Translating path to interspersed version...")

    interspersed_path =
      Enum.map(path, &translate_point_to_interspersed/1)
      # fill holes in the path
      |> Enum.reduce([], fn vertex, path ->
        if path == [] do
          [vertex]
        else
          {lx, ly} = last = hd(path)
          {cx, cy} = vertex

          between = {ceil((lx + cx) / 2), ceil((ly + cy) / 2)}

          [vertex, between | path]
        end
      end)
      |> Enum.reverse()

    # intersperse whole matrix
    # fill holes in the path
    # NO: go convolutionally from outside and mark as outside
    # from the edges to the inside so outside propagates
    # YES: walk the graph from every outside edge and mark the
    # adjacent edges as outside succesively
    # un-intersperse
    # count dots that are left

    IO.puts("Filling interspersed matrix with missing pipes...")

    filled =
      interspersed
      # |> MapMatrix.map_convolutional(fn _val, coords, conv_matrix ->
      #   is_in_path = Enum.member?(interspersed_path, coords)

      #   IO.puts("#{inspect(coords)}: #{inspect(conv_matrix)}")

      #   is_outside =
      #     MapMatrix.any?(conv_matrix, &(&1 == :out_of_bounds or &1 == "O"))

      #   IO.puts("#{is_outside}")

      #   # IO.puts("#{val}, #{inspect({x, y})}, #{conv_matrix |> MapMatrix.to_string()}")
      #   cond do
      #     is_in_path -> "P"
      #     is_outside -> "O"
      #     true -> "I"
      #   end
      # end)
      |> MapMatrix.map(fn val, coords ->
        is_to_fix = val == "." and Enum.member?(interspersed_path, coords)

        {top, bottom, left, right} = {
          MapMatrix.at(interspersed, MapMatrix.coords_moved_by(coords, {0, -1})),
          MapMatrix.at(interspersed, MapMatrix.coords_moved_by(coords, {0, 1})),
          MapMatrix.at(interspersed, MapMatrix.coords_moved_by(coords, {-1, 0})),
          MapMatrix.at(interspersed, MapMatrix.coords_moved_by(coords, {1, 0}))
        }

        cond do
          is_to_fix and PL.is_pipe?(top) and PL.is_pipe?(bottom) -> "|"
          is_to_fix and PL.is_pipe?(left) and PL.is_pipe?(right) -> "-"
          true -> val
        end
      end)

    # |> MapMatrix.to_string()
    # |> IO.puts()

    filled
    |> MapMatrix.to_string()
    |> then(&File.write!(dir_path <> input_file <> "-inter-filled", &1))

    IO.puts("Visualizing interspersed path...")
    # colored path
    filled
    |> MapMatrix.map(fn val, coords ->
      if Enum.member?(interspersed_path, coords) do
        IO.ANSI.red() <> val <> IO.ANSI.reset()
      else
        val
      end
    end)
    |> MapMatrix.to_string()
    |> tap(fn str ->
      File.write!(dir_path <> input_file <> "-inter-path-vis", str)
    end)

    IO.puts("Translating start coords to interspersed...")

    start_coords_interspersed =
      start_coords
      |> translate_point_to_interspersed()
      |> MapMatrix.coords_moved_by({1, 1})
      |> IO.inspect()

    IO.puts("Calculating full graph from interspersed and filled input...")

    maybe_vertices_inside_interspersed =
      filled
      |> MapMatrix.to_full_graph_of_coords()
      |> tap(fn _ ->
        IO.puts("Calculating vertices inside the path...")
      end)
      |> get_all_vertices_inside(interspersed_path, start_coords_interspersed)

    IO.puts("Translating vertices back to original coords and getting rid of artificial ones...")

    maybe_vertices_inside =
      maybe_vertices_inside_interspersed
      |> Enum.reject(fn {x, y} ->
        rem(x, 2) == 1 or rem(y, 2) == 1
      end)
      |> Enum.map(&translate_point_to_uninterspersed/1)
      |> IO.inspect()

    IO.puts("Visualizing found inside verticies...")
    # inside interspersed
    filled
    |> MapMatrix.map(fn val, coords ->
      if Enum.member?(maybe_vertices_inside_interspersed, coords) do
        IO.ANSI.red() <> val <> IO.ANSI.reset()
      else
        val
      end
    end)
    |> MapMatrix.to_string()
    |> tap(fn str ->
      File.write!(dir_path <> input_file <> "-inter-inside-vis", str)
    end)

    IO.puts("Visualizing inside vertices on origin input")

    matrix
    |> MapMatrix.map(fn val, coords ->
      if Enum.member?(maybe_vertices_inside, coords) do
        IO.ANSI.red() <> val <> IO.ANSI.reset()
      else
        val
      end
    end)
    |> MapMatrix.to_string()
    |> tap(&File.write!(dir_path <> input_file <> "-inside-original-vis", &1))

    IO.puts("Getting final results...")
    maybe_vertices_inside |> length() |> then(&IO.puts("vertices 'inside': #{&1}"))

    MapMatrix.size(matrix)
    |> then(fn {x, y} ->
      IO.puts("elements total: #{x * y}")
    end)

    path |> length() |> then(&IO.puts("path length: #{&1}"))

    # |> MapMatrix.map(fn val, coords ->
    #   cond do
    #     val == "x" -> val
    #     Enum.member?(interspersed_path, coords) -> val
    #     true -> "."
    #   end
    # end)
    # |> MapMatrix.to_string()
    # |> IO.puts()

    # File.write!("lib/aoc/10/parsed-3", path_only_string)
  end

  def translate_point_to_interspersed({x, y}) do
    {x * 2, y * 2}
  end

  def translate_point_to_uninterspersed({x, y}) do
    {trunc(x / 2), trunc(y / 2)}
  end

  def matrix_to_pipe_graph(matrix) do
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

  def get_all_vertices_inside(graph, loop_path, start_coords) do
    a = get_all_vertices_inside_step(graph, MapSet.new(loop_path), MapSet.new(), {133, 149})
    # b = get_all_vertices_inside_step(graph, MapSet.new(loop_path), MapSet.new(), {273, 123})

    # MapSet.union(a, b)

    a
  end

  @doc """
  Traverses as long as there is something to traverse
  """
  def get_all_vertices_inside_step(graph, loop_path, visited, vertex) do
    IO.puts("visited: #{MapSet.size(visited)}")

    adjacent = MapGraph.get_adjacent(graph, vertex)

    to_lookup =
      Enum.reject(adjacent, fn ad_vertex ->
        # TODO: speed up with sets?
        is_visited = MapSet.member?(visited, ad_vertex)
        is_part_of_the_loop = MapSet.member?(loop_path, ad_vertex)

        is_visited or is_part_of_the_loop
      end)

    new_visited = MapSet.put(visited, vertex)

    case to_lookup do
      [] ->
        new_visited

      some ->
        # recursive stream?
        Enum.reduce(some, new_visited, fn vertex_to_lookup, acc_visited ->
          get_all_vertices_inside_step(graph, loop_path, acc_visited, vertex_to_lookup)
        end)
    end
  end
end

# MapTensor?
