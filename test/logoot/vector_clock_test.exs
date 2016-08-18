defmodule Logoot.VectorClockTest do
  use ExUnit.Case, async: true
  doctest Logoot.VectorClock

  setup do
    {:ok, vector_clock} = Logoot.VectorClock.start_link
    {:ok, vector_clock: vector_clock}
  end

  test ".get_vector starts with 0 and increases by 1", %{vector_clock: clock} do
    assert Logoot.VectorClock.get_state(clock) == 0
    assert Logoot.VectorClock.get_state(clock) == 1
  end
end
