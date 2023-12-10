defmodule AOC.Day08 do
  import AOC.Utils

  # 714 punktow
  # 277 lewo-prawo
  # 6 punktow startowych
  # punkty końcowe zawsze po pełnej iteracji ścieżki
  # każdy punkt startowy ma swój końcowy

  # dla każdego punktu długość ścieżki do końca i potem NWW

  def parse_input(path) do
    [path, _ | map] =
      File.read!(path)
      |> String.split("\n")

    path = path |> String.trim() |> String.split("") |> Enum.reject(&is_empty_string/1)

    map =
      map
      |> Enum.map(fn point_def ->
        [name, pair] = String.split(point_def, " = ")

        [left, right] = pair |> String.replace(~r/[\(\),]/, "") |> String.split(" ")

        {name, {left, right}}
      end)
      |> Map.new(fn x -> x end)

    {path, map}
  end

  def run_part_1 do
    {path, map} = parse_input("lib/aoc/08/input")
    count_steps_to_zzz_1(path, map)
  end

  def count_steps_to_zzz_1(path, map) do
    path_tream = Stream.cycle(path)

    # recursive version
    # count_steps_to_zzz_rec(path_tream, map, "AAA", 0)

    {_, count} =
      Enum.reduce_while(path_tream, {"AAA", 0}, fn direction, {point_name, count} ->
        {left, right} = Map.get(map, point_name)

        next_point =
          case direction do
            "L" -> left
            "R" -> right
          end

        IO.inspect("#{point_name}, #{direction} -> #{next_point}")

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

  @start_to_end_example %{"11A" => "11Z", "22A" => "22Z"}

  def count_steps_from_to(path, map, start_point, end_point) do
    path_tream = Stream.cycle(path)

    {_, count} =
      Enum.reduce_while(path_tream, {start_point, 0}, fn direction, {point_name, count} ->
        {left, right} = Map.get(map, point_name)

        next_point =
          case direction do
            "L" -> left
            "R" -> right
          end

        IO.puts("#{point_name}, #{direction} -> #{next_point}")

        halt_or_cont =
          if next_point == end_point do
            :halt
          else
            :cont
          end

        {halt_or_cont, {next_point, count + 1}}
      end)

    count
  end

  def precompute_whole_paths_map(path, map) do
    Enum.map(map, fn point_name ->
      {name, _targets} = point_name

      new_target =
        Enum.reduce(path, name, fn direction, name ->
          {left, right} = Map.get(map, name)

          case direction do
            "L" -> left
            "R" -> right
          end
        end)

      {name, new_target}
    end)
    |> Map.new()
  end

  def run_part_2() do
    {path, map} = parse_input("lib/aoc/08/example-input-part-2")
    starting_points = get_starting_points(map)

    Enum.map(
      starting_points,
      &count_steps_from_to(path, map, &1, Map.get(@start_to_end_example, &1))
    )
    |> Enum.reduce(&lcm/2)
  end

  def lcm(a, b) do
    gcd = Integer.gcd(a, b)

    trunc(a / gcd * (b / gcd) * gcd)
  end

  def ends_with_A(str) do
    String.match?(str, ~r/[A]$/)
  end

  def ends_with_Z(str) do
    String.match?(str, ~r/[Z]$/)
  end

  def get_starting_points(map) do
    map
    |> Map.keys()
    |> Enum.filter(&ends_with_A/1)
  end

  def count_steps_on_precomputed(precomputed_map) do
    starting_points = get_starting_points(precomputed_map)

    {result, count} =
      Stream.cycle([1])
      |> Enum.reduce_while({starting_points, 0}, fn _, {points, count} ->
        # logging
        some_starting = Enum.any?(points, &ends_with_A/1)
        some_ending = Enum.any?(points, &ends_with_Z/1)

        if some_starting or some_ending do
          count_As = Enum.count(points, &ends_with_A/1)
          count_Zs = Enum.count(points, &ends_with_Z/1)

          if count_As > 2 or count_Zs > 2 do
            colored_points =
              Enum.map(points, fn point ->
                cond do
                  ends_with_A(point) -> IO.ANSI.blue() <> point <> IO.ANSI.reset()
                  ends_with_Z(point) -> IO.ANSI.red() <> point <> IO.ANSI.reset()
                  true -> point
                end
              end)
              |> Enum.join(", ")

            cond do
              some_starting and some_ending ->
                IO.puts("#{count}: #{colored_points} any with A or Z, #{count_As}, #{count_Zs}")

              some_starting ->
                IO.puts("#{count}: #{colored_points} any with A, #{count_As}")

              some_ending ->
                IO.puts("#{count}: #{colored_points} any with Z, #{count_Zs}")

              true ->
                nil
            end
          end
        end

        # end loggin

        next_points =
          Enum.map(points, fn point_name -> Map.get(precomputed_map, point_name) end)

        next_count = count + 1

        halt_or_cont =
          if Enum.all?(next_points, &ends_with_Z/1) do
            :halt
          else
            :cont
          end

        {halt_or_cont, {next_points, next_count}}
      end)

    IO.puts("result: #{inspect(result)}")

    count
  end

  def count_steps_to_zzz_2(path, map) do
    starting_points = get_starting_points(map)

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
