defmodule Logoot.Sequence do
  @moduledoc """
  A sequence of atoms identified by `Logoot.position_ident`s.
  """

  @max_pos 32767
  @min_sequence_atom {{[{0, 0}], 0}, nil}
  @max_sequence_atom {{[{@max_pos, 0}], 1}, nil}

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
  @type position_ident :: {position, non_neg_integer}

  @typedoc """
  An item in a sequence represented by a tuple `{position_ident, data}` where
  `position_ident` is a `position_ident` and `data` is any term.
  """
  @type sequence_atom  :: {position_ident, term}

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
  @type min_sequence_atom :: {{[{0, 0}], 0}, nil}

  @typedoc """
  A `sequence_atom` that represents the end of any `Logoot.Sequence.t`.
  """
  @type max_sequence_atom :: {{[{32767, 0}], 1}, nil}
end
