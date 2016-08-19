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

  test ".delete_atom deletes an atom from the agent", %{agent: agent} do
    agent_state = Logoot.Agent.tick_clock(agent)
    {:ok, atom_ident} =
      Sequence.gen_atom_ident(agent_state, Sequence.min, Sequence.max)
    atom = {atom_ident, "Hello, World"}

    {:ok, _sequence} =
      Logoot.Agent.insert_atom(agent, atom)
    Logoot.Agent.delete_atom(agent, atom)
    state = Logoot.Agent.get_state(agent)

    assert state.sequence == Sequence.empty_sequence
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

  test ".insert_atom survives basic fuzzing" do
    {:ok, agent_a_pid} = Logoot.Agent.start_link
    {:ok, agent_b_pid} = Logoot.Agent.start_link

    for _ <- 1..100 do
      {:ok, _} =
        agent_a_pid
        |> Logoot.Agent.insert_atom(gen_rand_atom(agent_a_pid))
      {:ok, _} =
        agent_b_pid
        |> Logoot.Agent.insert_atom(gen_rand_atom(agent_b_pid))
    end

    agent_a = Logoot.Agent.get_state(agent_a_pid)
    agent_b = Logoot.Agent.get_state(agent_b_pid)

    agent_a_sequence =
      agent_a.sequence
      |> Enum.map(&({agent_b_pid, &1}))

    agent_b_sequence =
      agent_b.sequence
      |> Enum.map(&({agent_a_pid, &1}))

    (agent_a_sequence ++ agent_b_sequence)
    |> Enum.shuffle
    |> Enum.each(fn {pid, atom} ->
      Logoot.Agent.insert_atom(pid, atom)
    end)

    agent_a = Logoot.Agent.get_state(agent_a_pid)
    agent_b = Logoot.Agent.get_state(agent_b_pid)

    assert agent_a.sequence == agent_b.sequence
  end

  defp gen_rand_atom(agent_pid) do
    %{sequence: sequence} = Logoot.Agent.get_state(agent_pid)
    prev_atom_index = :rand.uniform(length(sequence) - 1) - 1
    prev_atom  = Enum.at(sequence, prev_atom_index)
    next_atom  = Enum.at(sequence, prev_atom_index + 1)

    agent_state = Logoot.Agent.tick_clock(agent_pid)
    {:ok, atom_ident} = Sequence.gen_atom_ident(
      agent_state, elem(prev_atom, 0), elem(next_atom, 0))
    {atom_ident, UUID.uuid4(:hex)}
  end
end
