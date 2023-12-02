defmodule AdventOfCode.Day03 do
  @game_regex ~r/Game (.*):(.*)/
  @filename "input"
  @possible_maxes red: 12, green: 13, blue: 14

  # just so atoms are defined
  def colors() do
    [:red, :green, :blue]
  end

  def is_game_possible({_, game_maxes}, possible_maxes) do
    possible_maxes
    |> Enum.map(fn {color, possible_max} ->
      game_maxes[color] <= possible_max
    end)
    |> Enum.all?()
  end

  def parse_int(str) do
    {int, _} = Integer.parse(str)
    int
  end

  def parse_amount(amount_string) do
    amount_string
    |> String.trim()
    |> String.split(" ")
    |> then(fn [amount, color] ->
      {parse_int(amount), String.to_existing_atom(color)}
    end)
  end

  def parse_try(try_string) do
    try_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&parse_amount/1)
  end

  def get_maxes_of_tries(tries) do
    tries
    |> List.flatten()
    |> Enum.reduce(%{red: 0, green: 0, blue: 0}, fn {amount, color}, acc ->
      if amount > acc[color] do
        Map.put(acc, color, amount)
      else
        acc
      end
    end)
  end

  def parse_game(game_string) do
    [id_string, tries_string] = Regex.run(@game_regex, game_string, capture: :all_but_first)

    game_maxes =
      tries_string
      |> String.split(";")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&parse_try/1)
      |> get_maxes_of_tries()

    {parse_int(id_string), game_maxes}
  end

  def parse_games(lines) do
    lines
    |> Enum.map(&parse_game/1)
  end

  def solve_part_one(lines, possible_maxes) do
    lines
    |> parse_games()
    |> Enum.filter(&is_game_possible(&1, possible_maxes))
    |> Enum.reduce(0, fn {game_id, _}, acc -> acc + game_id end)
  end

  def power_of_set_of_cubes(%{red: red, green: green, blue: blue}) do
    red * green * blue
  end

  def solve_part_two(lines) do
    lines
    |> parse_games()
    |> Enum.map(fn {_id, maxes} -> power_of_set_of_cubes(maxes) end)
    |> Enum.sum()
  end

  def run_part_one() do
    File.stream!(@filename)
    |> solve_part_one(@possible_maxes)
  end

  def run_part_two() do
    File.stream!(@filename)
    |> solve_part_two()
  end
end
