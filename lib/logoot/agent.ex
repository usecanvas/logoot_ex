defmodule Logoot.Agent do
  @moduledoc """
  A GenServer which is represents a site at which a Logoot sequence is stored.
  The site has a unique copy of the sequence, a unique ID, and a vector clock.
  """

  use GenServer

  alias Logoot.Sequence

  defstruct id: "", clock: 0, sequence: Sequence.empty_sequence

  @type t :: %__MODULE__{id: String.t,
                         clock: non_neg_integer,
                         sequence: Sequence.t}

  # Client

  @doc """
  Start an agent whose initial clock value will be 0.
  """
  @spec start_link :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, %__MODULE__{id: gen_id})
  end

  @doc """
  Get the current state of the agent (ID and clock).
  """
  @spec get_state(pid) :: t
  def get_state(pid), do: GenServer.call(pid, :get_state)

  @doc """
  Increment the agent's clock by 1.
  """
  @spec tick_clock(pid) :: t
  def tick_clock(pid), do: GenServer.call(pid, :tick_clock)

  @doc """
  Insert an atom into the agent's sequence.
  """
  @spec insert_atom(pid, Sequence.sequence_atom) ::
    {:ok, Sequence.t} | {:error, String.t}
  def insert_atom(pid, atom), do: GenServer.call(pid, {:insert_atom, atom})

  @doc """
  Delete an atom from the agent's sequence.
  """
  @spec delete_atom(pid, Sequence.sequence_atom) :: Sequence.t
  def delete_atom(pid, atom), do: GenServer.call(pid, {:delete_atom, atom})

  # Generate a unique agent ID.
  @spec gen_id :: String.t
  defp gen_id, do: UUID.uuid4(:hex)

  # Tick an agent's clock by 1.
  @spec do_tick_clock(t) :: t
  defp do_tick_clock(agent), do: Map.put(agent, :clock, agent.clock + 1)

  # Server

  def handle_call(:get_state, _from, agent) do
    {:reply, agent, agent}
  end

  def handle_call({:insert_atom, atom}, _from, agent) do
    case Sequence.insert_atom(agent.sequence, atom) do
      error = {:error, _} -> {:reply, error, agent}
      {:ok, sequence} ->
        {:reply, {:ok, sequence}, Map.put(agent, :sequence, sequence)}
    end
  end

  def handle_call({:delete_atom, atom}, _from, agent) do
    sequence = Sequence.delete_atom(agent.sequence, atom)
    agent = Map.put(agent, :sequence, sequence)
    {:reply, sequence, agent}
  end

  def handle_call(:tick_clock, _from, agent) do
    agent = do_tick_clock(agent)
    {:reply, agent, agent}
  end
end
