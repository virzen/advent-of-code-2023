defmodule Day03 do
  defp is_digit(str) do
    Regex.match?(~r/[0-9]/, str)
  end

  def is_special_char(str) do
    not Regex.match?(~r/[0-9]|\./, str)
  end

  def is_gear_symbol(str) do
    str == "*"
  end

  def get_number(matrix, {y, x}) do
    row = Enum.at(matrix, y)

    row
    |> Enum.slice(x..999)
    |> Enum.reduce_while("", fn maybe_digit, acc ->
      if is_digit(maybe_digit) do
        {:cont, acc <> maybe_digit}
      else
        {:halt, acc}
      end
    end)
  end

  def is_within_bounds({row, col}, {rows, cols}) do
    if row > rows - 1 or col > cols - 1 or row < 0 or col < 0 do
      false
    else
      true
    end
  end

  def parse_int(x) do
    {int, ""} = Integer.parse(x)
    int
  end

  def generate_subsequent_cells(n, {row, col}) do
    for x <- 1..n do
      {row, col + x}
    end
  end

  def get_convolution_coords_around_number(num_len, {row, col}) do
    for y <- (row - 1)..(row + 1), x <- (col - 1)..(col + num_len) do
      if y == row and x >= col and x < col + num_len do
        nil
      else
        {y, x}
      end
    end
    |> Enum.reject(&is_nil/1)
  end

  def read_matrix(filename) do
    File.read!(filename)
    |> String.split()
    |> Enum.map(&String.codepoints/1)
  end

  def run_part_1 do
    m = read_matrix("input")

    # can be done via reduce too
    {:ok, visited_cells_agent} = Agent.start_link(fn -> [] end)

    {rows, cols} = Matrix.size(m)

    for row <- 0..(rows - 1), col <- 0..(cols - 1) do
      visited_cells = Agent.get(visited_cells_agent, fn v -> v end)
      elem = Matrix.elem(m, row, col)

      cond do
        # skip visited cells
        Enum.member?(visited_cells, {row, col}) ->
          nil

        # skip non-digits
        not is_digit(elem) ->
          nil

        true ->
          num = get_number(m, {row, col})
          num_len = String.length(num)

          has_adjacent_special_char =
            num_len
            |> get_convolution_coords_around_number({row, col})
            |> Enum.map(fn {row, col} ->
              elem = Matrix.elem(m, row, col)

              is_special_char(elem)
            end)
            |> Enum.any?(& &1)

          if has_adjacent_special_char do
            Agent.update(visited_cells_agent, fn v ->
              v ++ generate_subsequent_cells(num_len, {row, col})
            end)

            parse_int(num)
          else
            nil
          end
      end
    end
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
  end

  def run_part_2 do
    m = read_matrix("input")

    {rows, cols} = Matrix.size(m)

    # how else to get cartesian product? xd
    for row <- 0..(rows - 1), col <- 0..(cols - 1) do
      {row, col}
    end
    |> Enum.reduce(
      %{
        visited_cells: [],
        stars_map: %{}
      },
      fn {row, col}, acc ->
        %{visited_cells: visited_cells, stars_map: stars_map} = acc
        elem = Matrix.elem(m, row, col)

        is_visited = Enum.member?(visited_cells, {row, col})

        cond do
          # skip visited cells
          is_visited ->
            acc

          # skip non-digits
          not is_digit(elem) ->
            acc

          true ->
            num = get_number(m, {row, col})
            num_len = String.length(num)

            gear_cells =
              num_len
              |> get_convolution_coords_around_number({row, col})
              |> Enum.filter(&is_within_bounds(&1, {rows, cols}))
              |> Enum.filter(fn {row, col} -> is_gear_symbol(Matrix.elem(m, row, col)) end)

            num_int = parse_int(num)

            new_stars_map =
              Enum.reduce(gear_cells, stars_map, fn {row, col}, stars_map ->
                Map.update(stars_map, {row, col}, [num_int], fn nums -> [num_int] ++ nums end)
              end)

            %{
              visited_cells: visited_cells ++ generate_subsequent_cells(num_len, {row, col}),
              stars_map: new_stars_map
            }
        end
      end
    )
    |> then(& &1.stars_map)
    |> Map.filter(fn {_key, val} -> length(val) == 2 end)
    |> Map.values()
    |> IO.inspect()
    |> Enum.map(fn [a, b] -> a * b end)
    |> IO.inspect()
    |> Enum.sum()
  end
end
