defmodule Logoot.SequenceTest do
  use ExUnit.Case

  alias Logoot.Sequence

  setup do
    {:ok, agent} = Logoot.Agent.start_link
    state = Logoot.Agent.get_state(agent)
    {:ok, state: state}
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
    test "returns a valid atom_ident between abs min and max", %{state: state} do
      {:ok, atom_ident} =
        Sequence.gen_atom_ident(state, Sequence.min, Sequence.max)
      assert(
        Sequence.compare_atom_idents(atom_ident, Sequence.min) == :gt)
      assert(
        Sequence.compare_atom_idents(atom_ident, Sequence.max) == :lt)
    end

    test "returns a valid atom_ident between min and max", %{state: state} do
      min = {[{1, 1}, {1, 3}, {1, 4}], 39}
      max = {[{1, 1}, {1, 3}, {1, 4}, {3, 5}], 542}
      {:ok, atom_ident} =
        Sequence.gen_atom_ident(state, min, max)
      assert(Sequence.compare_atom_idents(atom_ident, min) == :gt)
      assert(Sequence.compare_atom_idents(atom_ident, max) == :lt)
    end
  end

  describe ".get_and_insert_after" do
    test "inserts data after the given atom identifier", %{state: state} do
      sequence = Sequence.empty_sequence

      {:ok, {atom, sequence}} =
        sequence
        |> Sequence.get_and_insert_after(Sequence.min, "Hello, World!", state)

      assert sequence == [{Sequence.min, nil}, atom, {Sequence.max, nil}]
    end
  end

  describe ".insert_atom" do
    test "inserts an atom into its proper position", %{state: state} do
      min = Sequence.min
      max = Sequence.max
      mid = {elem(Sequence.gen_atom_ident(state, min, max), 1), "Foo"}
      sequence = [{min, nil}, mid, {max, nil}]
      {:ok, atom_ident} = Sequence.gen_atom_ident(state, elem(mid, 0), max)
      atom = {atom_ident, "Bar"}
      {:ok, sequence} =
        Sequence.insert_atom(sequence, atom)
      assert sequence == [{min, nil}, mid, atom, {max, nil}]
    end

    test "inserts idempotently", %{state: state} do
      min = Sequence.min
      max = Sequence.max
      sequence = Sequence.empty_sequence
      {:ok, atom_ident} = Sequence.gen_atom_ident(state, min, max)
      atom = {atom_ident, "Bar"}
      {:ok, sequence} =
        Sequence.insert_atom(sequence, atom)
      {:ok, sequence} =
        Sequence.insert_atom(sequence, atom)
      assert sequence == [{min, nil}, atom, {max, nil}]
    end
  end

  describe ".delete_atom" do
    test "is idempotent", %{state: state} do
      sequence = Sequence.empty_sequence

      {:ok, {atom, sequence}} =
        sequence
        |> Sequence.get_and_insert_after(Sequence.min, "Hello, World!", state)

      sequence =
        sequence
        |> Sequence.delete_atom(atom)
        |> Sequence.delete_atom(atom)

      assert sequence == [{Sequence.min, nil}, {Sequence.max, nil}]
    end

    test "deletes the given atom", %{state: state} do
      sequence = Sequence.empty_sequence

      {:ok, {atom, sequence}} =
        sequence
        |> Sequence.get_and_insert_after(Sequence.min, "Hello, World!", state)

      sequence = sequence |> Sequence.delete_atom(atom)
      assert sequence == [{Sequence.min, nil}, {Sequence.max, nil}]
    end
  end

  test ".values gets the values without min and max", %{state: state} do
    min = Sequence.min
    max = Sequence.max
    foo = {elem(Sequence.gen_atom_ident(state, min, max), 1), "Foo"}
    bar = {elem(Sequence.gen_atom_ident(state, elem(foo, 0), max), 1), "Bar"}

    values =
      Sequence.empty_sequence
      |> Sequence.insert_atom(foo)
      |> elem(1)
      |> Sequence.insert_atom(bar)
      |> elem(1)
      |> Sequence.get_values

    assert values == ["Foo", "Bar"]
  end
end
