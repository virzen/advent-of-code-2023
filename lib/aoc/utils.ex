defmodule AOC.Utils do
  def parse_int(str) do
    {int, _} = Integer.parse(str)
    int
  end

  def is_digit(str) do
    Regex.match?(~r/[0-9]/, str)
  end

  def is_empty_string(str) do
    str == ""
  end

  def id(x) do
    x
  end

  def cartesian_product(enumerable1, enumerable2) do
    Enum.reduce(enumerable1, [], fn elem, acc ->
      Enum.zip(List.duplicate(elem, length(enumerable2)), enumerable2) ++ acc
    end)
    |> List.flatten()
  end

  def cartesian_product(enumerable) do
    cartesian_product(enumerable, enumerable)
  end

  # what is the number of subsets of enumerable of length n?
  def combination_2(enumerable) do
    {result, _} =
      Enum.reduce(enumerable, {[], enumerable}, fn elem, {result, elems_left} ->
        left_except_current = Enum.reject(elems_left, & &1 == elem)

        new_pick =
          elem
          |> List.duplicate(length(elems_left) - 1)
          |> Enum.zip(left_except_current)

        [_ | new_elems_left] = elems_left

        {
          new_pick ++ result,
          new_elems_left
        }
      end)

    List.flatten(result)
  end
end
