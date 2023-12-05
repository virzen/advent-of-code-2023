defmodule AOC.Ex00 do
  def process(input) do
    input
    |> String.codepoints()
    |> Enum.map(fn
      "(" -> 1
      ")" -> -1
    end)
    |> Enum.reduce(%{count: 1, sum: 0, count_at_basement: -1}, fn el,
                                                                  %{
                                                                    sum: sum,
                                                                    count: count,
                                                                    count_at_basement:
                                                                      count_at_basement
                                                                  } ->
      new_sum = sum + el

      new_count_at_basement =
        if count_at_basement == -1 and new_sum < 0 do
          count
        else
          count_at_basement
        end

      %{
        sum: new_sum,
        count: count + 1,
        count_at_basement: new_count_at_basement
      }
    end)
  end

  def run() do
    File.read!("input")
    |> process()
  end
end
