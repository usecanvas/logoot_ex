defmodule Logoot.SequenceTest do
  use ExUnit.Case

  alias Logoot.Sequence

  setup do
    {:ok, agent} = Logoot.Agent.start_link
    {:ok, agent: agent}
  end

  describe ".compare_position_ident" do
    # Note that vector clock values are different in these comparisons. This is
    # allowed, because it is not possible for the same site to generate the
    # same line.
    test "is equal when they are empty" do
      assert(
        Sequence.compare_position_idents({[], 1}, {[], 2}) == :eq)
    end

    test "is equal when they are identical" do
      comparison =
        Sequence.compare_position_idents(
          {[{1, 3}, {1, 4}], 0},
          {[{1, 3}, {1, 4}], 29})
      assert comparison == :eq
    end

    test "is greater-than when they are of equal length with a greater-than" do
      comparison =
        Sequence.compare_position_idents(
          {[{1, 3}, {1, 5}], 0},
          {[{1, 3}, {1, 4}], 29})
      assert comparison == :gt
    end

    test "is greater-than when they are of unequal length with a greater-than" do
      comparison =
        Sequence.compare_position_idents(
          {[{1, 3}, {1, 4}, {1, 2}], 0},
          {[{1, 3}, {1, 4}], 29})
      assert comparison == :gt
    end

    test "is less-than when they are of equal length with a less-than" do
      comparison =
        Sequence.compare_position_idents(
          {[{1, 3}, {1, 4}], 0},
          {[{1, 3}, {1, 5}], 29})
      assert comparison == :lt
    end

    test "is less-than when they are of unequal length with a less-than" do
      comparison =
        Sequence.compare_position_idents(
          {[{1, 3}, {1, 4}], 0},
          {[{1, 3}, {1, 4}, {1, 2}], 29})
      assert comparison == :lt
    end
  end

  describe ".get_position_ident" do
    test "returns a valid position_ident between abs min and max", %{agent: agent} do
      position_ident =
        Sequence.gen_position_ident(agent, Sequence.min, Sequence.max)
      assert(
        Sequence.compare_position_idents(position_ident, Sequence.min) == :gt)
      assert(
        Sequence.compare_position_idents(position_ident, Sequence.max) == :lt)
    end

    test "returns a valid position_ident between min and max", %{agent: agent} do
      min = {[{1, 1}, {1, 3}, {1, 4}], 39}
      max = {[{1, 1}, {1, 3}, {1, 4}, {3, 5}], 542}
      position_ident =
        Sequence.gen_position_ident(agent, min, max)
      assert(Sequence.compare_position_idents(position_ident, min) == :gt)
      assert(Sequence.compare_position_idents(position_ident, max) == :lt)
    end
  end
end
