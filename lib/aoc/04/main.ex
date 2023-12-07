defmodule AOC.Day04 do
  import AOC.Utils

  def count_points(how_many_numbers) do
    case how_many_numbers do
      0 ->
        0

      1 ->
        1

      _n ->
        1..(how_many_numbers - 1)
        |> Enum.reduce(1, fn _x, acc ->
          acc * 2
        end)
    end
  end

  def is_empty_string(str) do
    str == ""
  end

  def parse_numbers(numbers_string) do
    numbers_string
    |> String.trim()
    |> String.split(" ")
    |> Enum.reject(&is_empty_string/1)
    |> Enum.map(&parse_int/1)
    |> MapSet.new()
  end

  def get_card_result(winning, main) do
    MapSet.intersection(winning, main)
    |> MapSet.size()
  end

  def run_part_1 do
    File.stream!("input")
    |> Enum.map(fn line ->
      [_, right] = String.split(line, ":", parts: 2)

      [winning, main] =
        String.split(right, "|")
        |> Enum.map(&parse_numbers/1)

      get_card_result(winning, main)
      |> count_points()
    end)
    |> Enum.sum()
  end

  def put_copies(copies, card_num, times, 0) do
    copies
  end

  def put_copies(copies, card_num, times, result) do
    for x <- (card_num + 1)..(card_num + result) do
      x
    end
    |> Enum.reduce(copies, fn x, acc ->
      Map.update(acc, x, times, fn current -> current + times end)
    end)
  end

  def run_part_2 do
    File.stream!("input")
    |> Enum.reduce([copies_per_card: %{}, count: 0], fn line,
                                                        [
                                                          copies_per_card: copies_per_card,
                                                          count: count
                                                        ] ->
      [left, right] = String.split(line, ":", parts: 2)

      card_num =
        String.split(left, " ")
        |> List.last()
        |> parse_int()

      [winning, main] =
        String.split(right, "|")
        |> Enum.map(&parse_numbers/1)

      card_result = get_card_result(winning, main) |> IO.inspect()

      copies_of_current_card = Map.get(copies_per_card, card_num, 0)

      total_current_cards = 1 + copies_of_current_card

      new_copies =
        put_copies(copies_per_card, card_num, total_current_cards, card_result)

      [
        copies_per_card: new_copies,
        count: count + total_current_cards
      ]
      |> IO.inspect()
    end)
    |> then(& &1[:count])
  end
end
