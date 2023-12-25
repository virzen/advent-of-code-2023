defmodule AOC.D11.SpaceImage do
  @moduledoc """
  Uses MapMatrix as ds.
  """

  alias AOC.MapMatrix

  @galaxy_sign "#"
  @space_sign "."

  def is_galaxy(space_or_galaxy) do
    space_or_galaxy == @galaxy_sign
  end

  def contains_galaxy(enumerable) do
    Enum.any?(enumerable, &is_galaxy/1)
  end

  def from_string(str) do
    MapMatrix.from_string(str)
  end

  def expand(space_image, n \\ 2) do
    rows_to_duplicate =
      space_image
      |> MapMatrix.rows_indexed()
      |> Enum.reject(fn {_, row} -> contains_galaxy(row) end)
      |> Enum.map(fn {index, _} -> index end)

    # move each subsequent row by n indexes to account for
    # inserting rows before
    # |> then(fn indexes ->
    #   indexes
    #   |> Enum.zip(0..(length(indexes) - 1))
    #   |> Enum.map(fn {index, count} -> index + (count * n) end)
    # end)

    columns_to_duplicate =
      space_image
      |> MapMatrix.columns_indexed()
      |> Enum.reject(fn {_, column} -> contains_galaxy(column) end)
      |> Enum.map(fn {index, _} -> index end)

    # move each subsequent column by n indexes to account for
    # inserting columns before
    # |> then(fn indexes ->
    #   indexes
    #   |> Enum.zip(0..(length(indexes) - 1))
    #   |> Enum.map(fn {index, count} -> index + (count * n) end)
    # end)

    {rows_to_duplicate, columns_to_duplicate}

    # space_image
    # |> then(fn space_image ->
    #   Enum.reduce(rows_to_duplicate, space_image, fn y, acc ->
    #     Enum.reduce(0..(n-2), acc, fn nn, acc ->
    #       MapMatrix.insert_row(acc, y + nn, @space_sign)
    #     end)
    #   end)
    # end)
    # |> then(fn space_image ->
    #   Enum.reduce(columns_to_duplicate, space_image, fn x, acc ->
    #     Enum.reduce(0..(n-2), acc, fn nn, acc ->
    #       MapMatrix.insert_column(acc, x + nn, @space_sign)
    #     end)
    #   end)
    # end)
  end

  def find_galaxies(space_image) do
    MapMatrix.find_all_coords(space_image, fn cell, _ -> is_galaxy(cell) end)
  end
end

defmodule AOC.D11 do
  alias AOC.MapGraph
  alias AOC.Utils
  alias AOC.MapMatrix
  alias AOC.D11.SpaceImage

  def run() do
    dir_path = "lib/aoc/11/"
    file_name = "input"

    original =
      File.read!(dir_path <> file_name)
      |> SpaceImage.from_string()
      |> MapMatrix.debug()

    # expanded =
    #   original
    #   |> SpaceImage.expand(10)
    #   |> MapMatrix.debug()

    # full_graph =
    #   MapMatrix.to_full_graph_of_coords_vert_hor(expanded)

    galaxies =
      SpaceImage.find_galaxies(original)

    # SpaceImage.find_galaxies(original)

    {rows_to_duplicate, columns_to_duplicate} = SpaceImage.expand(original) |> IO.inspect()

    how_many_expanded_between = fn from, to ->
      {fx, fy} = from
      {tx, ty} = to

      rows_count =
        rows_to_duplicate
        |> Enum.filter(fn y ->
          if fy < ty do
            fy < y and y < ty
          else
            ty < y and y < fy
          end
        end)
        |> length()

      columns_count =
        columns_to_duplicate
        |> Enum.filter(fn x ->
          if fx < tx do
            fx < x and x < tx
          else
            tx < x and x < fx
          end
        end)
        |> length()

      {rows_count, columns_count}
    end

    all_paths_between_galaxies =
      Utils.combination_2(galaxies)

    n = 1_000_000

    all_paths_between_galaxies
    |> Enum.map(fn {from, to} ->
      # IO.puts("Calculating #{inspect(from)} -> #{inspect(to)}")

      {expanded_rows, expanded_columns} = how_many_expanded_between.(from, to)

      {fx, fy} = from
      {dx, dy} = to

      abs(fx - dx) + abs(fy - dy) + expanded_rows * (n - 1) + expanded_columns * (n - 1)

      # path =
      #   full_graph
      #   |> MapGraph.find_shortest_path(from, to, fn coords ->
      #     {cx, cy} = coords
      #     {dx, dy} = to
      #     abs(cx - dx) + abs(cy - dy)
      #   end)

      # # vis
      # middle_path =
      #   Enum.slice(path, 1..(length(path) - 2))

      # expanded
      # |> MapMatrix.map(fn val, coords ->
      #   if Enum.member?(middle_path, coords) do
      #     "X"
      #   else
      #     val
      #   end
      # end)
      # |> MapMatrix.to_string()
      # |> IO.puts()

      # path
    end)
    # |> Enum.map(fn path ->
    #   [_ | rest_of_path] = path

    #   length(rest_of_path)
    # end)
    |> Enum.sum()
    |> IO.inspect()
  end
end
