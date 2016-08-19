defmodule Logoot.SequenceTest do
  use ExUnit.Case

  alias Logoot.Sequence

  setup do
    {:ok, agent} = Logoot.Agent.start_link
    {:ok, agent: agent}
  end

  describe ".compare_atom_ident" do
    # Note that vector clock values are different in these comparisons. This is
    # allowed, because it is not possible for the same site to generate the
    # same line.
    test "is equal when they are empty" do
      assert(
        Sequence.compare_atom_idents({[], 1}, {[], 2}) == :eq)
    end

    test "is equal when they are identical" do
      comparison =
        Sequence.compare_atom_idents(
          {[{1, 3}, {1, 4}], 0},
          {[{1, 3}, {1, 4}], 29})
      assert comparison == :eq
    end

    test "is greater-than when they are of equal length with a greater-than" do
      comparison =
        Sequence.compare_atom_idents(
          {[{1, 3}, {1, 5}], 0},
          {[{1, 3}, {1, 4}], 29})
      assert comparison == :gt
    end

    test "is greater-than when they are of unequal length with a greater-than" do
      comparison =
        Sequence.compare_atom_idents(
          {[{1, 3}, {1, 4}, {1, 2}], 0},
          {[{1, 3}, {1, 4}], 29})
      assert comparison == :gt
    end

    test "is less-than when they are of equal length with a less-than" do
      comparison =
        Sequence.compare_atom_idents(
          {[{1, 3}, {1, 4}], 0},
          {[{1, 3}, {1, 5}], 29})
      assert comparison == :lt
    end

    test "is less-than when they are of unequal length with a less-than" do
      comparison =
        Sequence.compare_atom_idents(
          {[{1, 3}, {1, 4}], 0},
          {[{1, 3}, {1, 4}, {1, 2}], 29})
      assert comparison == :lt
    end
  end

  describe ".get_atom_ident" do
    test "returns a valid atom_ident between abs min and max", %{agent: agent} do
      {:ok, atom_ident} =
        Sequence.gen_atom_ident(agent, Sequence.min, Sequence.max)
      assert(
        Sequence.compare_atom_idents(atom_ident, Sequence.min) == :gt)
      assert(
        Sequence.compare_atom_idents(atom_ident, Sequence.max) == :lt)
    end

    test "returns a valid atom_ident between min and max", %{agent: agent} do
      min = {[{1, 1}, {1, 3}, {1, 4}], 39}
      max = {[{1, 1}, {1, 3}, {1, 4}, {3, 5}], 542}
      {:ok, atom_ident} =
        Sequence.gen_atom_ident(agent, min, max)
      assert(Sequence.compare_atom_idents(atom_ident, min) == :gt)
      assert(Sequence.compare_atom_idents(atom_ident, max) == :lt)
    end
  end

  describe ".get_and_insert_after" do
    test "inserts data after the given atom identifier", %{agent: agent} do
      sequence = [{Sequence.min, nil}, {Sequence.max, nil}]

      {:ok, {atom, sequence}} =
        sequence
        |> Sequence.get_and_insert_after(Sequence.min, "Hello, World!", agent)

      assert sequence == [{Sequence.min, nil}, atom, {Sequence.max, nil}]
    end
  end

  describe ".insert_atom" do
    test "inserts an atom into its proper position", %{agent: agent} do
      min = Sequence.min
      max = Sequence.max
      mid = {elem(Sequence.gen_atom_ident(agent, min, max), 1), "Foo"}
      sequence = [{min, nil}, mid, {max, nil}]
      {:ok, atom_ident} = Sequence.gen_atom_ident(agent, elem(mid, 0), max)
      atom = {atom_ident, "Bar"}
      {:ok, sequence} =
        Sequence.insert_atom(sequence, atom)
      assert sequence == [{min, nil}, mid, atom, {max, nil}]
    end

    test "inserts idempotently", %{agent: agent} do
      min = Sequence.min
      max = Sequence.max
      sequence = [{min, nil}, {max, nil}]
      {:ok, atom_ident} = Sequence.gen_atom_ident(agent, min, max)
      atom = {atom_ident, "Bar"}
      {:ok, sequence} =
        Sequence.insert_atom(sequence, atom)
      {:ok, sequence} =
        Sequence.insert_atom(sequence, atom)
      assert sequence == [{min, nil}, atom, {max, nil}]
    end
  end

  describe ".delete_atom" do
    test "is idempotent", %{agent: agent} do
      sequence = [{Sequence.min, nil}, {Sequence.max, nil}]

      {:ok, {atom, sequence}} =
        sequence
        |> Sequence.get_and_insert_after(Sequence.min, "Hello, World!", agent)

      sequence =
        sequence
        |> Sequence.delete_atom(atom)
        |> Sequence.delete_atom(atom)

      assert sequence == [{Sequence.min, nil}, {Sequence.max, nil}]
    end

    test "deletes the given atom", %{agent: agent} do
      sequence = [{Sequence.min, nil}, {Sequence.max, nil}]

      {:ok, {atom, sequence}} =
        sequence
        |> Sequence.get_and_insert_after(Sequence.min, "Hello, World!", agent)

      sequence = sequence |> Sequence.delete_atom(atom)
      assert sequence == [{Sequence.min, nil}, {Sequence.max, nil}]
    end
  end
end
