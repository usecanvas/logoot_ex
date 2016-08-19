defmodule Logoot.AgentTest do
  use ExUnit.Case, async: true
  doctest Logoot.Agent

  alias Logoot.Sequence

  setup do
    {:ok, agent} = Logoot.Agent.start_link
    {:ok, agent: agent}
  end

  test ".get_state gets the state of the agent", %{agent: agent} do
    state = Logoot.Agent.get_state(agent)
    assert state.clock == 0
    assert is_binary(state.id)
  end

  test ".insert_atom inserts the atom into the agent", %{agent: agent} do
    agent_state = Logoot.Agent.tick_clock(agent)
    {:ok, atom_ident} =
      Sequence.gen_atom_ident(agent_state, Sequence.min, Sequence.max)
    atom = {atom_ident, "Hello, World"}

    {:ok, sequence} =
      Logoot.Agent.insert_atom(agent, atom)

    assert sequence == [{Sequence.min, nil}, atom, {Sequence.max, nil}]
  end
end
