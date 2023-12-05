defmodule AOC.Utils do
  def parse_int(str) do
    {int, _} = Integer.parse(str)
    int
  end

  defp is_digit(str) do
    Regex.match?(~r/[0-9]/, str)
  end
end
