defmodule Logoot.Agent do
  @moduledoc """
  A GenServer which is responsible for storing the state of a vector clock for
  use in generating `Logoot.Sequence.position_ident`s.

      iex> {:ok, agent} = Logoot.Agent.start_link
      iex> Logoot.Agent.get_vector(agent)
      0
      iex> Logoot.Agent.get_vector(agent)
      1
  """

  use GenServer

  # Client

  def start_link do
    GenServer.start_link(__MODULE__, 0)
  end

  def get_vector(pid) do
    GenServer.call(pid, :get_vector)
  end

  # Server

  def handle_call(:get_vector, _from, current_vector) do
    {:reply, current_vector, current_vector + 1}
  end
end
