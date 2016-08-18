defmodule Logoot.AgentTest do
  use ExUnit.Case

  setup do
    {:ok, agent} = Logoot.Agent.start_link
    {:ok, agent: agent}
  end

  test ".get_vector starts with 0 and increases by 1", %{agent: agent} do
    assert Logoot.Agent.get_vector(agent) == 0
    assert Logoot.Agent.get_vector(agent) == 1
  end
end
