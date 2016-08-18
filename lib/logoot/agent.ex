defmodule Logoot.Agent do
  @moduledoc """
  A GenServer which is responsible for storing a unique ID and the state of a
  vector clock for use in generating `Logoot.Sequence.position_ident`s.

      iex> {:ok, agent} = Logoot.Agent.start_link
      iex> Logoot.Agent.get_clock(agent)
      0
      iex> Logoot.Agent.tick_clock(agent)
      1
  """

  use GenServer

  defstruct id: "", clock: 0

  @type t :: %__MODULE__{id: String.t, clock: non_neg_integer}

  # Client

  @doc """
  Start an agent whose initial clock value will be 0.
  """
  @spec start_link :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, %__MODULE__{id: gen_id, clock: 0})
  end

  @doc """
  Get the current value of an agent's clock.
  """
  @spec get_clock(pid) :: non_neg_integer
  def get_clock(pid), do: GenServer.call(pid, :get_clock)

  @doc """
  Get the current state of the agent (ID and clock).
  """
  @spec get_state(pid) :: t
  def get_state(pid), do: GenServer.call(pid, :get_state)

  @doc """
  Increment the agent's clock by 1.
  """
  @spec tick_clock(pid) :: pos_integer
  def tick_clock(pid), do: GenServer.call(pid, :tick_clock)

  # Generate a unique agent ID.
  @spec gen_id :: String.t
  defp gen_id, do: UUID.uuid4(:hex)

  # Server

  def handle_call(:get_clock, _from, agent) do
    {:reply, agent.clock, agent}
  end

  def handle_call(:get_state, _from, agent) do
    {:reply, agent, agent}
  end

  def handle_call(:tick_clock, _from, agent) do
    clock_value = agent.clock + 1
    {:reply, clock_value, agent |> Map.put(:clock, clock_value)}
  end
end
