defmodule Logoot.AgentTest do
  use ExUnit.Case, async: true
  doctest Logoot.Agent

  setup do
    {:ok, agent} = Logoot.Agent.start_link
    {:ok, agent: agent}
  end

  test ".get_clock starts with 0", %{agent: agent} do
    assert Logoot.Agent.get_clock(agent) == 0
  end

  test ".get_state gets the state of the agent", %{agent: agent} do
    state = Logoot.Agent.get_state(agent)
    assert state.clock == 0
    assert is_binary(state.id)
  end

  test ".tick_clock increments the agent's clock", %{agent: agent} do
    assert Logoot.Agent.tick_clock(agent) == 1
    assert Logoot.Agent.tick_clock(agent) == 2
    assert Logoot.Agent.get_clock(agent) ==   2
  end
end
