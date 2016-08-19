defmodule Logoot.Sequence do
  @moduledoc """
  A sequence of atoms identified by `Logoot.atom_ident`s.
  """

  @max_pos 32767
  @abs_min_atom_ident {[{0, 0}], 0}
  @abs_max_atom_ident {[{@max_pos, 0}], 1}

  @typedoc """
  The result of a comparison.
  """
  @type comparison :: :gt | :lt | :eq

  @typedoc """
  A tuple `{int, site}`where `int` is an integer and `site` is a site
  identifier.
  """
  @type ident :: {0..32767, term}

  @typedoc """
  A list of `ident`s.
  """
  @type position :: [ident]

  @typedoc """
  A tuple `{pos, v}` generated at site `s` where
  `^pos = [ident_1, ident_2, {int, ^s}]` is a position and `v` is the value of
  the vector clock of site `s`.
  """
  @type atom_ident :: {position, non_neg_integer}

  @typedoc """
  An item in a sequence represented by a tuple `{atom_ident, data}` where
  `atom_ident` is a `atom_ident` and `data` is any term.
  """
  @type sequence_atom  :: {atom_ident, term}

  @typedoc """
  A sequence of `sequence_atoms` used to represent an ordered set.

  The first atom in a sequence will always be `@min_sequence_atom` and the last
  will always be `@max_sequence_atom`.

      [
        {{[{0, 0}], 0}, nil},
        {{[{1, 1}], 0}, "This is an example of a Logoot Sequence"},
        {{[{1, 1}, {1, 5}], 23}, "How to find a place between 1 and 1"},
        {{[{1, 3}], 2}, "This line was the third made on replica 3"},
        {{[{32767, 0}], 1}, nil}
      ]
  """
  @type t :: [sequence_atom]

  @typedoc """
  A `sequence_atom` that represents the beginning of any `Logoot.Sequence.t`.
  """
  @type abs_min_atom_ident :: {nonempty_list({0, 0}), 0}

  @typedoc """
  A `sequence_atom` that represents the end of any `Logoot.Sequence.t`.
  """
  @type abs_max_atom_ident :: {nonempty_list({32767, 0}), 1}

  @doc """
  Get the minimum sequence atom.
  """
  @spec min :: abs_min_atom_ident
  def min, do: @abs_min_atom_ident

  @doc """
  Get the maximum sequence atom.
  """
  @spec max :: abs_max_atom_ident
  def max, do: @abs_max_atom_ident

  @doc """
  Compare two atom identifiers.

  Returns `:gt` if first is greater than second, `:lt` if it is less, and `:eq`
  if they are equal.
  """
  @spec compare_atom_idents(atom_ident, atom_ident) :: comparison
  def compare_atom_idents(atom_ident_a, atom_ident_b) do
    compare_positions(elem(atom_ident_a, 0), elem(atom_ident_b, 0))
  end

  @doc """
  Delete the given atom from the sequence.
  """
  @spec delete_atom(t, sequence_atom) :: t
  def delete_atom([atom | tail], atom), do: tail
  def delete_atom([head | tail], atom), do: [head | delete_atom(tail, atom)]
  def delete_atom([], _atom), do: []

  @doc """
  Get the empty sequence.
  """
  @spec empty_sequence :: [{abs_min_atom_ident | abs_max_atom_ident, nil}]
  def empty_sequence, do: [{min, nil}, {max, nil}]

  @doc """
  Insert a value into a sequence after the given atom identifier.

  Returns a tuple containing `{:ok, {new_atom, updated_sequence}}` or
  `{:error, message}`.
  """
  @spec get_and_insert_after(t, atom_ident, term, Logoot.Agent.t) ::
        {:ok, {sequence_atom, t}} | {:error, String.t}
  def get_and_insert_after(sequence, prev_sibling_ident, value, agent) do
    prev_sibling_index =
      Enum.find_index(sequence, fn {atom_ident, _} ->
        atom_ident == prev_sibling_ident
      end)

    {next_sibling_ident, _} = Enum.at(sequence, prev_sibling_index + 1)

    case gen_atom_ident(agent, prev_sibling_ident, next_sibling_ident) do
      error = {:error, _} -> error
      {:ok, atom_ident} ->
        new_atom = {atom_ident, value}

        {:ok,
         {new_atom, List.insert_at(sequence, prev_sibling_index + 1, new_atom)}}
    end
  end

  @doc """
  Insert the given atom into the sequence.
  """
  @spec insert_atom(t, sequence_atom) :: {:ok, t} | {:error, String.t}
  def insert_atom(list = [prev | tail = [next | _]], atom) do
    {{prev_position, _}, _} = prev
    {{next_position, _}, _} = next
    {{position, _}, _} = atom

    case {compare_positions(position, prev_position),
          compare_positions(position, next_position)} do
      {:gt, :lt} ->
        {:ok, [prev | [atom | tail]]}
      {:gt, :gt} ->
        case insert_atom(tail, atom) do
          error = {:error, _} -> error
          {:ok, tail} -> {:ok, [prev | tail]}
        end
      {:lt, :gt} ->
        {:error, "Sequence out of order"}
      {:eq, _} ->
        {:ok, list}
      {_, :eq} ->
        {:ok, list}
    end
  end

  @doc """
  Generate an atom identifier between `min` and `max`.
  """
  @spec gen_atom_ident(Logoot.Agent.t, atom_ident, atom_ident) ::
        {:ok, atom_ident} | {:error, String.t}
  def gen_atom_ident(agent, min_atom_ident, max_atom_ident) do
    case gen_position(agent.id,
                      elem(min_atom_ident, 0),
                      elem(max_atom_ident, 0)) do
      error = {:error, _} -> error
      atom_ident          -> {:ok, {atom_ident, agent.clock}}
    end
  end

  @doc """
  Return only the values from the sequence.
  """
  @spec get_values(t) :: [term]
  def get_values(sequence) do
    sequence
    |> Enum.slice(1..-2)
    |> Enum.map(&(elem(&1, 1)))
  end

  # Compare two positions.
  @spec compare_positions(position, position) :: comparison
  defp compare_positions([], []), do: :eq
  defp compare_positions(_, []), do: :gt
  defp compare_positions([], _), do: :lt

  defp compare_positions([head_a | tail_a], [head_b | tail_b]) do
    case compare_idents(head_a, head_b) do
      :gt -> :gt
      :lt -> :lt
      :eq -> compare_positions(tail_a, tail_b)
    end
  end

  # Generate a position from an agent ID, min, and max
  @spec gen_position(String.t, position, position) ::
        nonempty_list(ident) | {:error, String.t}
  defp gen_position(agent_id, min_position, max_position) do
    {min_head, min_tail} = get_logical_head_tail(min_position, :min)
    {max_head, max_tail} = get_logical_head_tail(max_position, :max)

    {min_int, min_id} = min_head
    {max_int, _max_id} = max_head

    case compare_idents(min_head, max_head) do
      :lt ->
        case max_int - min_int do
          diff when diff > 1 ->
            [{random_int_between(min_int, max_int), agent_id}]
          diff when diff == 1 and agent_id > min_id ->
            [{min_int, agent_id}]
          _diff ->
            [min_head | gen_position(agent_id, min_tail, max_tail)]
        end
      :eq ->
        [min_head | gen_position(agent_id, min_tail, max_tail)]
      :gt ->
        {:error, "Max atom was lesser than min atom"}
    end
  end

  # Get the logical min or max head and tail.
  @spec get_logical_head_tail(position, :min | :max) :: {ident, position}
  defp get_logical_head_tail([], :min), do: {Enum.at(elem(min, 0), 0), []}
  defp get_logical_head_tail([], :max), do: {Enum.at(elem(max, 0), 0), []}
  defp get_logical_head_tail(position, _), do: {hd(position), tl(position)}

  # Generate a random int between two ints.
  @spec random_int_between(0..32767, 1..32767) :: 1..32766
  defp random_int_between(min, max) do
    :rand.uniform(max - min - 1) + min
  end

  # Compare two `ident`s, returning `:gt` if first is greater than second,
  # `:lt` if first is less than second, `:eq` if equal.
  @spec compare_idents(ident, ident) :: comparison
  defp compare_idents({int_a, _}, {int_b, _}) when int_a > int_b, do: :gt
  defp compare_idents({int_a, _}, {int_b, _}) when int_a < int_b, do: :lt
  defp compare_idents({_, site_a}, {_, site_b}) when site_a > site_b, do: :gt
  defp compare_idents({_, site_a}, {_, site_b}) when site_a < site_b, do: :lt
  defp compare_idents(_, _), do: :eq
end
