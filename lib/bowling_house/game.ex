defmodule BowlingHouse.GameManager do
  use GenServer
  alias BowlingHouse.GameEngine

  @ets_table :bowling_game

  @impl true
  def init(opts) do
    {:ok, opts, {:continue, :setup_ets}}
  end

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl true
  def handle_continue(:setup_ets, state) do
    :ets.new(@ets_table, [:set, :public, :named_table])

    {:noreply, state}
  end

  # Client APIS
  # def new

  def new(game_id) do
    :ets.insert_new(@ets_table, {game_id, _game_state = []})

    # not handling get_game_state :not_found return here because
    # ^^ would either insert a new record or fail if a record exists
    start_game_engine(game_id, _state = get_game_state(game_id))
  end

  def roll(game_id, no_of_pins) when is_integer(no_of_pins) and no_of_pins < 11 do
    case maybe_start_and_call_game_engine(game_id, {:throw_ball, no_of_pins}) do
      {res, new_game_state} when res in [:hit, :exceed_frame_limit] ->
        upsert_ets(game_id, new_game_state)
        {res, new_game_state}

      {:end_of_game, new_game_state} ->
        # delete the record from ets
        # terminate the supervisor?
        {:end_of_game, new_game_state}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def reset_state(game_id) do
    upsert_ets(game_id, [])
    maybe_start_and_call_game_engine(game_id, :reset)
  end

  def get_game_score(game_id) do
    maybe_start_and_call_game_engine(game_id, :game_score)
  end

  def get_game_state(game_id) do
    case :ets.lookup(@ets_table, game_id) do
      [] ->
        :not_found

      [{_game_id, game_state}] ->
        game_state
    end
  end

  def end_game(game_id) do
    :ets.delete(@ets_table, game_id)

    try do
      GenServer.call(via_tuple(game_id), :end)
      :ok
    catch
      :exit, _ -> :ok
    end
  end

  defp maybe_start_and_call_game_engine(game_id, command) do
    try do
      GenServer.call(via_tuple(game_id), command)
    catch
      :exit, {:noproc, _} ->
        # game engine not started probably because the game child process died
        # start game engine with the current state in ETS
        case get_game_state(game_id) do
          :not_found ->
            {:error, :not_found}

          game_state ->
            :ok = start_game_engine(game_id, _state = game_state)
            maybe_start_and_call_game_engine(game_id, command)
        end
    end
  end

  defp start_game_engine(game_id, state) do
    case DynamicSupervisor.start_child(
           BowlingHouse.GameEngineSupervisor,
           {GameEngine, name: via_tuple(game_id), default_state: state}
         ) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  defp via_tuple(game_id) do
    {:via, Registry, {BowlingHouse.GameEngineRegistry, game_id}}
  end

  defp upsert_ets(game_id, state) do
    :ets.insert(@ets_table, {game_id, _frames = state})
  end
end
