defmodule AOC.Day06 do
  import AOC.Utils

  def run_part_1 do
    [times, distances] =
      File.read!("lib/aoc/06/input")
      |> String.split("\n")

    times =
      times
      |> String.split(" ")
      |> Enum.reject(&is_empty_string/1)
      |> Enum.slice(1, 999)
      |> Enum.map(&parse_int/1)

    distances =
      distances
      |> String.split(" ")
      |> Enum.reject(&is_empty_string/1)
      |> Enum.slice(1, 999)
      |> Enum.map(&parse_int/1)

    Enum.zip(times, distances)
    |> Enum.map(fn {total_time, max_distance} ->
      for speed <- 0..total_time do
        speed * (total_time - speed)
      end
      |> Enum.filter(&(&1 > max_distance))
      |> length()
    end)
    |> Enum.reduce(&Kernel.*/2)
  end

  def run_part_2 do
    [times, distances] =
      File.read!("lib/aoc/06/example-input")
      |> String.split("\n")

    time =
      times
      |> String.split(" ")
      |> Enum.reject(&is_empty_string/1)
      |> Enum.slice(1, 999)
      |> Enum.join()
      |> parse_int()

    distance =
      distances
      |> String.split(" ")
      |> Enum.reject(&is_empty_string/1)
      |> Enum.slice(1, 999)
      |> Enum.join()
      |> parse_int()

    IO.inspect(time)
    IO.inspect(distance)

    for speed <- 0..time do
      speed * (time - speed)
    end
    |> Enum.filter(&(&1 > distance))
    |> length()
  end
end
