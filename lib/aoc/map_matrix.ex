defmodule AOC.MapMatrix do
  @moduledoc """
  Creates map-based matrix representation, in the form of %{ {x, y} => value }
  Assumes the size of the last row to be the width of the matrix.

  Coordinates are 0-based.

  TODO: use struct to pattern match on this exact structure instead of accepting
  any map, like MapSet.

  Could implement Enumerable protocol.

  Could be generalized to MapTensor and still implement Enumerable protocol
  (map, slice, take etc., with some special function back in
  MapMatrix/MapTensor).
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

  def find_all_coords(matrix, f) do
    {width, height} = size(matrix)

    for x <- 0..(width - 1),
        y <- 0..(height - 1),
        f.(at(matrix, {x, y}), {x, y}) do
      {x, y}
    end
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

  def get_column(matrix, x) do
    {_, height} = size(matrix)

    # macro?
    for y <- 0..(height - 1) do
      {x, y}
    end
    |> Enum.map(&at(matrix, &1))
  end

  def rows(matrix) do
    {_, height} = size(matrix)

    for y <- 0..(height - 1) do
      matrix
      |> get_row(y)
    end
  end

  def rows_indexed(matrix) do
    {_, height} = size(matrix)

    for y <- 0..(height - 1) do
      {y, get_row(matrix, y)}
    end
  end

  def columns_indexed(matrix) do
    {width, _} = size(matrix)

    for x <- 0..(width - 1) do
      {x, get_column(matrix, x)}
    end
  end

  @doc """
  Insert row into the matrix. If row is a list it is inserted as is, if is a single value then is repeated width-of-the-array times.
  """
  def insert_row(matrix, y, row) when is_list(row) do
    {width, height} = size(matrix)

    new_row_map =
      for x <- 0..(width - 1) do
        {x, y}
      end
      |> Enum.zip(row)
      |> Map.new()

    # moving other rows
    new_entries =
      for x <- 0..(width - 1), ny <- y..(height - 1) do
        {{x, ny + 1}, at(matrix, {x, ny})}
      end
      |> Map.new()

    [matrix, new_entries, new_row_map, %{height: height + 1}]
    |> Enum.reduce(fn map, acc -> Map.merge(acc, map) end)
  end

  def insert_row(matrix, y, value) do
    {width, _height} = size(matrix)

    row = List.duplicate(value, width)

    insert_row(matrix, y, row)
  end

  def insert_column(matrix, x, column) when is_list(column) do
    {width, height} = size(matrix)

    new_column_map =
      for y <- 0..(height - 1) do
        {x, y}
      end
      |> Enum.zip(column)
      |> Map.new()

    # moving other columns
    new_entries =
      for nx <- x..(width - 1), y <- 0..(height - 1) do
        {{nx + 1, y}, at(matrix, {nx, y})}
      end
      |> Map.new()

    [matrix, new_entries, new_column_map, %{width: width + 1}]
    |> Enum.reduce(fn map, acc -> Map.merge(acc, map) end)
  end

  def insert_column(matrix, x, value) do
    {_, height} = size(matrix)

    column = List.duplicate(value, height)

    insert_column(matrix, x, column)
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
      |> from_string()

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
      {{div(x, 2), div(y, 2)}, at(matrix, coords)}
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
    |> Enum.map(&{&1, at(matrix, &1)})
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
    |> map(fn _val, coords ->
      matrix
      |> get_convolution_matrix(coords)
      |> Map.drop([:width, :height])
      |> Enum.filter(fn {_key, val} -> val != :out_of_bounds end)
      |> Map.new()
      |> Map.keys()
    end)
    |> Map.drop([:height, :width])
  end

  def to_full_graph_of_coords_vert_hor(matrix) do
    get_cross_cells = fn matrix, coords ->
      [
        {0, -1},
        {1, 0},
        {0, 1},
        {-1, 0}
      ]
      |> Enum.map(fn delta -> coords_moved_by(coords, delta) end)
      |> Enum.map(fn coords -> {coords, at(matrix, coords)} end)
    end

    matrix
    |> map(fn _val, coords ->
      matrix
      |> get_cross_cells.(coords)
      |> Enum.filter(fn {_key, val} -> val != :out_of_bounds end)
      |> Map.new()
      |> Map.keys()
    end)
    |> Map.drop([:height, :width])
  end

  def debug(matrix) do
    matrix
    |> __MODULE__.to_string()
    |> IO.puts()

    matrix
  end
end
