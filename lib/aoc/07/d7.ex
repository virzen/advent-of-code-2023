defmodule AOC.D7 do
  import AOC.Utils

  # five > four > full house (3-2) > three > two pair > one pair > high card

  def compare_hands(left, right, card_order_variant \\ :first) do
    {{left_type, _, left_cards} = left_hand, _} = left
    {{right_type, _, right_cards} = right_hand, _} = right
    left_order = get_order(left_hand)
    right_order = get_order(right_hand)

    get_card_order =
      case card_order_variant do
        :first -> &get_card_order/1
        :second -> &get_card_order_2/1
      end

    result =
      cond do
        # left higher than right, should supercede
        left_order < right_order ->
          false

        # left lower than right, should precede
        left_order > right_order ->
          true

        left_order == right_order ->
          left_card_orders = Enum.map(left_cards, &get_card_order.(&1))
          right_card_orders = Enum.map(right_cards, &get_card_order.(&1))

          which_card_wins =
            Enum.zip(left_card_orders, right_card_orders)
            |> Enum.map(fn {left_card, right_card} ->
              cond do
                left_card < right_card -> :left
                left_card > right_card -> :right
                true -> :eq
              end
            end)
            |> Enum.find(fn x -> x == :left or x == :right end)

          if is_nil(which_card_wins) do
            raise "No card won, basically the same hands, what to do? #{inspect(left)} #{inspect(right)}"
          else
            case which_card_wins do
              # left should be later
              :left -> false
              # right should be later
              :right -> true
            end
          end
      end

    # IO.puts(
    #   "#{left_type} #{Enum.join(left_cards)} vs #{right_type} #{Enum.join(right_cards)} -> #{result}"
    # )

    result
  end

  def type_order() do
    [:five, :four, :full_house, :three, :two_pair, :one_pair, :high_card]
  end

  def get_order({type, _, _}) do
    Enum.find_index(type_order(), &(&1 == type))
  end

  def card_order() do
    ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"]
  end

  def card_order_2() do
    ["A", "K", "Q", "T", "9", "8", "7", "6", "5", "4", "3", "2", "J"]
  end

  def get_card_order(card) do
    Enum.find_index(card_order(), &(&1 == card))
  end

  def get_card_order_2(card) do
    Enum.find_index(card_order_2(), &(&1 == card))
  end

  def has_all(enumerable, items) when is_list(items) do
    items
    |> Enum.map(fn item ->
      has(enumerable, item)
    end)
    |> Enum.all?()
  end

  def has(enumerable, item) do
    Enum.member?(enumerable, item)
  end

  def parse_hand(hand_string) do
    cards = hand_string |> String.split("") |> Enum.reject(&is_empty_string/1)

    groups = Enum.group_by(cards, &id/1)

    counts = groups |> Enum.map(fn {_key, cards} -> length(cards) end)

    cond do
      has(counts, 5) ->
        card = groups |> Map.keys() |> hd
        {:five, card, cards}

      has(counts, 4) ->
        {card, _value} = groups |> Enum.find(fn {_key, value} -> length(value) == 4 end)
        {:four, card, cards}

      has_all(counts, [3, 2]) ->
        {card_1, _value} = groups |> Enum.find(fn {_key, value} -> length(value) == 3 end)
        {card_2, _value} = groups |> Enum.find(fn {_key, value} -> length(value) == 2 end)
        {:full_house, [card_1, card_2], cards}

      has(counts, 3) ->
        {card, _value} = groups |> Enum.find(fn {_key, value} -> length(value) == 3 end)
        {:three, card, cards}

      Enum.sort(counts, :desc) == [2, 2, 1] ->
        pair_cards =
          groups
          |> Enum.filter(fn {_key, value} -> length(value) == 2 end)
          |> Enum.map(fn {card, _val} -> card end)

        {:two_pair, pair_cards, cards}

      Enum.sort(counts, :desc) == [2, 1, 1, 1] ->
        {card, _value} = groups |> Enum.find(fn {_key, value} -> length(value) == 2 end)
        {:one_pair, card, cards}

      true ->
        {:high_card, nil, cards}
    end
  end

  def parse_hand_2(hand_string) do
    {type, _card, cards} = hand = parse_hand(hand_string)

    jokers = Enum.count(cards, &(&1 == "J"))

    new_type =
      case type do
        :five ->
          :five

        :four ->
          if jokers == 1 or jokers == 4 do
            :five
          else
            :four
          end

        :full_house ->
          if jokers == 3 or jokers == 2 do
            :five
          else
            :full_house
          end

        :three ->
          if jokers == 1 or jokers == 3 do
            :four
          else
            :three
          end

        :two_pair ->
          cond do
            jokers == 2 -> :four
            jokers == 1 -> :full_house
            true -> :two_pair
          end

        :one_pair ->
          if jokers == 1 or jokers == 2 do
            :three
          else
            :one_pair
          end

        :high_card ->
          if jokers == 1 do
            :one_pair
          else
            :high_card
          end
      end

    new_hand = {new_type, nil, cards}

    # IO.inspect("#{Enum.join(cards)} #{type} #{jokers} -> #{new_type}")

    new_hand
  end

  def solve_part_1(input) do
    input
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(fn line ->
      [hand_string, bid_string] = String.split(line, " ")

      hand = parse_hand(hand_string)
      bid = parse_int(bid_string)

      {hand, bid}
    end)
    |> Enum.sort(&compare_hands/2)
    |> then(&Enum.zip(&1, 1..length(&1)))
    |> tap(fn results ->
      IO.inspect(Enum.take(results, -10))
    end)
    |> Enum.map(fn {{_cards, bid}, rank} ->
      bid * rank
    end)
    |> Enum.sum()
  end

  def run_part_1_example do
    File.read!("lib/aoc/07/example-input")
    |> solve_part_1()
  end

  def run_part_1 do
    File.read!("lib/aoc/07/input")
    |> solve_part_1()
  end

  def solve_part_2(input) do
    input
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(fn line ->
      [hand_string, bid_string] = String.split(line, " ")

      hand = parse_hand_2(hand_string)
      bid = parse_int(bid_string)

      {hand, bid}
    end)
    |> Enum.sort(&compare_hands(&1, &2, :second))
    |> then(&Enum.zip(&1, 1..length(&1)))
    |> tap(fn results ->
      Enum.each(results, &IO.inspect/1)
    end)
    |> Enum.map(fn {{_cards, bid}, rank} ->
      bid * rank
    end)
    |> Enum.sum()
  end

  def run_part_2 do
    File.read!("lib/aoc/07/input")
    |> solve_part_2()
  end

  def run_part_2_example do
    File.read!("lib/aoc/07/example-input")
    |> solve_part_2()
  end
end
