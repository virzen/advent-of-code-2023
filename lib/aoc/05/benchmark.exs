alias AOC.Day05

example_input = Day05.read_input(:example)
input = Day05.read_input(:input)

subset_size = 24_000_000

Benchee.run(
  %{
    "chunk 1_000" => fn ->
      Day05.run_part_2(input, subset_size: subset_size, chunk_size: 1_000)
    end,
    "chunk 10_000" => fn ->
      Day05.run_part_2(input, subset_size: subset_size, chunk_size: 10_000)
    end,
    "chunk 75_000" => fn ->
      Day05.run_part_2(input, subset_size: subset_size, chunk_size: 75_000)
    end,
    "chunk 150_000" => fn ->
      Day05.run_part_2(input, subset_size: subset_size, chunk_size: 150_000)
    end,
    "chunk 500_000" => fn ->
      Day05.run_part_2(input, subset_size: subset_size, chunk_size: 10_000)
    end,
    "chunk 1_000_000" => fn ->
      Day05.run_part_2(input, subset_size: subset_size, chunk_size: 1_000_000)
    end,
    "chunk 2_000_000" => fn ->
      Day05.run_part_2(input, subset_size: subset_size, chunk_size: 2_000_000)
    end
  },
  time: 30
)
