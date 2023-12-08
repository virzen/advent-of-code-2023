defmodule AOC.Day05 do
  import AOC.Utils

  defmodule MapRange do
    @moduledoc """
    Inclusive.
    """
    defstruct [:start, :finish, :destination_start]

    def new(source_start, destination_start, length) do
      if length < 1 do
        raise "MapRange must of positive length, #{length} given"
      end

      %MapRange{
        start: source_start,
        finish: source_start + length - 1,
        destination_start: destination_start
      }
    end

    def is_in_range(%MapRange{start: start, finish: finish} = _map_range, num) do
      num >= start and num <= finish
    end

    def map(%MapRange{start: start, destination_start: destination_start} = map_range, num) do
      if not is_in_range(map_range, num) do
        raise "#{num} not in range #{inspect(map_range)}"
      else
        num - start + destination_start
      end
    end
  end

  def get_sections(file) do
    String.split(file, "\n\n")
  end

  def get_individual_seeds(sections) do
    [seeds_line | rest] = sections

    seeds =
      seeds_line
      |> String.split(":")
      |> Enum.at(1)
      |> String.trim()
      |> String.split(" ")
      |> Enum.map(&AOC.Utils.parse_int/1)

    {seeds, rest}
  end

  def raport_stream_progress(stream, total, step \\ 1_000_000) do
    stream
    |> Stream.transform(0, fn elem, counter ->
      {[{elem, counter + 1}], counter + 1}
    end)
    |> Stream.map_every(step, fn {_, counter} = elem ->
      progress = counter / total * 100

      IO.puts("#{progress}%")

      elem
    end)
    |> Stream.map(fn {seed, _counter} -> seed end)
  end

  def stream_of_range([start, length]) do
    start
    # Stream.unfold
    |> Stream.iterate(&(&1 + 1))
    |> Stream.take(length)
  end

  @subset_size 100
  @chunk_size 75_000

  def get_seed_ranges(sections) do
    {seeds, rest} = get_individual_seeds(sections)

    ranges =
      seeds
      |> Enum.chunk_every(2)

    sum =
      ranges
      |> Enum.map(fn [_start, length] -> length end)
      |> Enum.sum()

    IO.puts("#{sum / 1_000_000} mln seeds to map")
    IO.puts("#{sum / @chunk_size} chunks to process")

    unfolded =
      ranges
      |> Enum.map(&stream_of_range/1)
      |> Stream.concat()
      # |> Stream.take(@subset_size)
      # could be extracted to count_progress
      |> raport_stream_progress(sum, 1_000_000)

    {unfolded, rest}
  end

  def get_map_range_of_section(section) do
    section
    |> String.split(":")
    |> Enum.at(1)
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&String.split(&1, " "))
    |> Enum.map(fn range_string ->
      [destination, source, length] = Enum.map(range_string, &parse_int/1)

      MapRange.new(source, destination, length)
    end)
  end

  def get_ranges({seeds, mapping_lines}) do
    ranges =
      mapping_lines
      |> Enum.map(&get_map_range_of_section/1)

    {seeds, ranges}
  end

  def apply_mapping(resource, ranges = _mapping) do
    Enum.reduce_while(ranges, resource, fn range, resource ->
      if MapRange.is_in_range(range, resource) do
        {:halt, MapRange.map(range, resource)}
      else
        {:cont, resource}
      end
    end)
  end

  def apply_all_mappings(seed, mappings) do
    Enum.reduce(mappings, seed, fn mapping, resource ->
      apply_mapping(resource, mapping)
    end)
  end

  def get_locations_for_seeds({seeds, mappings}) do
    for seed <- seeds do
      apply_all_mappings(seed, mappings)
    end
  end

  def time(fun) do
    {time, value} = :timer.tc(fun, :millisecond)

    IO.puts("function executed in #{time} ms")

    value
  end

  def get_locations_for_seeds_lazily({seeds_stream, mappings}) do
    seeds_stream
    # |> Stream.map(fn seed ->
    #   apply_all_mappings(seed, mappings)
    # end)
    |> Stream.chunk_every(@chunk_size)
    |> Task.async_stream(fn seeds_chunk ->
      # on separate process!
      # IO.puts("starting chunk starting with #{hd(seeds_chunk)}")

      min =
        seeds_chunk
        |> Stream.map(fn seed ->
          apply_all_mappings(seed, mappings)
        end)
        |> Enum.min()

      # IO.puts("finished chunk with min #{min}")

      min
    end)
    |> Stream.map(fn {:ok, num} -> num end)
  end

  def run_part_1 do
    # split by \n\n
    # take seeds from the first section
    # read subsequent sections
    # build a map? range? what? pipeline?
    # read locations for all the seeds
    # choose smallest one
    File.read!("input")
    |> get_sections()
    |> get_individual_seeds()
    |> IO.inspect()
    |> get_ranges()
    |> IO.inspect()
    |> get_locations_for_seeds()
    |> IO.inspect()
    |> Enum.min()
  end

  def run_part_2(input) do
    filename =
      case input do
        :input -> "lib/aoc/05/input"
        :example -> "lib/aoc/05/example-input"
      end

    File.read!(filename)
    |> get_sections()
    |> get_seed_ranges()
    |> get_ranges()
    |> get_locations_for_seeds_lazily()
    |> Enum.min()
  end
end
