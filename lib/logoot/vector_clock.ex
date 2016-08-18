defmodule Logoot.VectorClock do
  @moduledoc """
  A GenServer which is responsible for storing the state of a vector clock for
  use in generating `Logoot.Sequence.position_ident`s.

      iex> {:ok, vector_clock} = Logoot.VectorClock.start_link
      iex> Logoot.VectorClock.get_state(vector_clock)
      0
      iex> Logoot.VectorClock.get_state(vector_clock)
      1
  """

  use GenServer

  # Client

  @doc """
  Start a vector clock whose initial value will be 0.
  """
  @spec start_link :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, 0)
  end

  @doc """
  Get the current value of a vector clock.
  """
  @spec get_state(pid) :: non_neg_integer
  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # Server

  @spec handle_call(:get_state, GenServer.from, non_neg_integer) ::
        {:reply, non_neg_integer, non_neg_integer}
  def handle_call(:get_state, _from, state) do
    {:reply, state, state + 1}
  end
end
