defmodule AOC.D9 do
  import AOC.Utils

  def get_pre_first(list) do
    IO.inspect(list)

    {_, reduced} =
      Enum.reduce(list, {nil, []}, fn num, {prev, list} ->
        if is_nil(prev) do
          {num, []}
        else
          {num, [num - prev | list]}
        end
      end)

    if Enum.sum(reduced) == 0 do
      hd(list)
    else
      # reverse each time could be avoided in favor of one reverse at the
      # beginning and one at the end?
      List.first(list) - get_pre_first(Enum.reverse(reduced))
    end
  end

  def run_example_1() do
    File.stream!("lib/aoc/09/input")
    |> Stream.map(fn line ->
      line
      # parsing
      |> String.trim()
      |> String.split(" ")
      |> Enum.map(&parse_int/1)
      # reduction
      |> IO.inspect()
      |> then(&get_pre_first/1)
      |> IO.inspect()
    end)
    |> Enum.sum()
  end
end
