defmodule AOC.Day01.Part2 do
  @filename "input"
  @regex ~r/[1-9]|one|two|three|four|five|six|seven|eight|nine/
  @reverted_regex ~r/[1-9]|eno|owt|eerht|ruof|evif|xis|neves|thgie|enin/

  def get_first_digit(line) do
    Regex.run(@regex, line) |> hd
  end

  def get_last_digit(line) do
    line
    |> String.reverse()
    |> then(&Regex.run(@reverted_regex, &1))
    # assumes there is always a match
    |> hd()
    |> String.reverse()
  end

  def digit_to_number(word_or_digit) do
    case word_or_digit do
      "one" -> "1"
      "two" -> "2"
      "three" -> "3"
      "four" -> "4"
      "five" -> "5"
      "six" -> "6"
      "seven" -> "7"
      "eight" -> "8"
      "nine" -> "9"
      # passes through bad data, but it's ok for now
      digit -> digit
    end
  end

  def parse_int(str) do
    {int, _} = Integer.parse(str)
    int
  end

  def process_line(line) do
    first = get_first_digit(line) |> digit_to_number()
    last = get_last_digit(line) |> digit_to_number()

    parse_int(first <> last)
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
