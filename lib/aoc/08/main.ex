defmodule AOC.Day08 do
  import AOC.Utils

  # 714 punktow
  # 277 lewo-prawo
  # 6 punktow startowych

  def parse_input(path) do
    [path, _ | points] =
      File.read!(path)
      |> String.split("\n")

    path = path |> String.trim() |> String.split("") |> Enum.reject(&is_empty_string/1)

    points =
      points
      |> Enum.map(fn point_def ->
        [name, pair] = String.split(point_def, " = ")

        [left, right] = pair |> String.replace(~r/[\(\),]/, "") |> String.split(" ")

        {name, {left, right}}
      end)
      |> Map.new(fn x -> x end)

    {path, points}
  end

  def run_part_1 do
    {path, points} = parse_input("lib/aoc/08/input")
    count_steps_to_zzz_1(path, points)
  end

  def count_steps_to_zzz_1(path, map) do
    path_tream = Stream.cycle(path)

    # recursive version
    # count_steps_to_zzz_rec(path_tream, map, "AAA", 0)

    {_, count} =
      Enum.reduce_while(path_tream, {"AAA", 0}, fn direction, {point, count} ->
        {left, right} = Map.get(map, point)

        next_point =
          case direction do
            "L" -> left
            "R" -> right
          end

        IO.inspect("#{point}, #{direction} -> #{next_point}")

        halt_or_cont =
          if next_point == "ZZZ" do
            :halt
          else
            :cont
          end

        {halt_or_cont, {next_point, count + 1}}
      end)

    count
  end

  def run_part_2() do
    {path, points} = parse_input("lib/aoc/08/input")
    count_steps_to_zzz_2(path, points)
  end

  def ends_with_A(str) do
    String.match?(str, ~r/[A]$/)
  end

  def ends_with_Z(str) do
    String.match?(str, ~r/[Z]$/)
  end

  def count_steps_to_zzz_2(path, map) do
    starting_points =
      map
      |> Map.keys()
      |> Enum.filter(&ends_with_A/1)

    # IO.inspect(starting_points, map)

    counted_path =
      Enum.zip(path, 1..length(path))

    path_stream =
      Stream.cycle(counted_path)
      |> Stream.transform(0, fn {direction, path_counter}, counter ->
        {[{direction, path_counter, counter + 1}], counter + 1}
      end)

    # |> Stream.map_every(1_000_000, fn {_, counter} = elem ->
    #   IO.puts("#{counter / 1_000_000} mlns")
    #   elem
    # end)
    # |> Stream.map(fn {seed, _counter} -> seed end)

    {_points, count} =
      Enum.reduce_while(path_stream, {starting_points, 0}, fn {direction, path_counter,
                                                               total_counter},
                                                              {points, count} ->
        some_starting = Enum.any?(points, &ends_with_A/1)
        some_ending = Enum.any?(points, &ends_with_Z/1)
        count_As = Enum.count(points, &ends_with_A/1)
        count_Zs = Enum.count(points, &ends_with_Z/1)
        path_iteration = div(count, 277)

        cond do
          some_starting and some_ending ->
            IO.puts(
              "#{inspect(points)} any with A or Z, #{path_counter}, #{count_As}, #{count_Zs}, #{path_iteration}, #{count}"
            )

          some_starting ->
            IO.puts(
              "#{inspect(points)} any with A, #{path_counter}, #{count_As}, #{path_iteration}, #{count}"
            )

          some_ending ->
            IO.puts(
              "#{inspect(points)} any with Z, #{path_counter}, #{count_Zs}, #{path_iteration}, #{count}"
            )

          true ->
            nil
        end

        next_points =
          points
          |> Enum.map(fn point_name ->
            {left, right} = Map.get(map, point_name)

            case direction do
              "L" -> left
              "R" -> right
            end
          end)

        halt_or_cont =
          if Enum.all?(next_points, &ends_with_Z/1) do
            :halt
          else
            :cont
          end

        {halt_or_cont, {next_points, count + 1}}
      end)

    count
  end
end
