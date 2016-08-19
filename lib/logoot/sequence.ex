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
  @type abs_min_atom_ident :: {[{0, 0}], 0}

  @typedoc """
  A `sequence_atom` that represents the end of any `Logoot.Sequence.t`.
  """
  @type abs_max_atom_ident :: {[{32767, 0}], 1}

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

  @doc """
  Generate an atom identifier between `min` and `max`.
  """
  @spec gen_atom_ident(pid, atom_ident, atom_ident) ::
        atom_ident
  def gen_atom_ident(agent_pid, min_atom_ident, max_atom_ident) do
    agent = Logoot.Agent.tick_clock(agent_pid)
    atom_ident =
      gen_position(agent.id, elem(min_atom_ident, 0), elem(max_atom_ident, 0))
    {atom_ident, agent.clock}
  end

  # Generate a position from an agent ID, min, and max
  @spec gen_position(String.t, position, position) :: position
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
    end
  end

  # Get the logical min or max head and tail.
  @spec get_logical_head_tail(position, :min) :: {ident, position}
  defp get_logical_head_tail([], :min), do: {Enum.at(elem(min, 0), 0), []}
  defp get_logical_head_tail([], :max), do: {Enum.at(elem(max, 0), 0), []}
  defp get_logical_head_tail(position, _), do: {hd(position), tl(position)}

  # Generate a random int between two ints.
  @spec random_int_between(non_neg_integer, pos_integer) :: pos_integer
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
