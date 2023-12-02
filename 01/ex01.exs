defmodule AdventOfCode.Ex01 do
  @filename "input"
  @regex ~r/[1-9]/

  def get_first_digit(line) do
    Regex.run(@regex, line) |> hd
  end

  def parse_int(str) do
    {int, _} = Integer.parse(str)
    int
  end

  def process_line(line) do
    parse_int(get_first_digit(line) <> get_first_digit(String.reverse(line)))
  end

  def run() do
    File.stream!(@filename)
    |> Enum.map(fn
      "" ->
        0

      line ->
        process_line(line)
    end)
    |> Enum.reduce(0, &Kernel.+/2)
  end
end

IO.puts("#{AdventOfCode.Ex01.run()}")
