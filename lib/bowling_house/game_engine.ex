defmodule BowlingHouse.GameEngine do
  use GenServer

  alias BowlingHouse.Frame
  @bonus_point 10

  @doc """
  Start our queue and link it.
  This is a helper function
  """
  def start_link(options) when is_list(options) do
    name = Keyword.fetch!(options, :name)
    default_state = Keyword.get(options, :default_state, [])
    GenServer.start_link(__MODULE__, default_state, name: name)
  end

  @doc """
  GenServer.init/1 callback
  """
  @impl true
  def init(state), do: {:ok, state}

  def handle_call({:throw_ball, hits}, _from, []) do
    # this is the first hit by the user
    frame = %Frame{
      first_throw_pins_hits: hits,
      score: hits
    }

    {:reply, {_message = :hit, _updated_frames = [frame]}, [frame]}
  end

  def handle_call({:throw_ball, hits}, _from, frames) do
    [last_frame | reversed_frames] = Enum.reverse(frames)

    {message, updated_frames} =
      cond do
        # we can only have 11 frames if the player made a strike or spare in the 10th frame.
        # This is the bonus frame

        # if the player hit a strike in the 10th game, allow one more hit
        Enum.count(frames) == 11 && Frame.strike?(Enum.at(frames, 10)) ->
          update_and_append_frame(hits, last_frame, reversed_frames)

        # if the 10th frame wasn't a strike, and we are at the bonus frame, we end the game
        Enum.count(frames) == 11 ->
          {:end_of_game, frames}

        Enum.count(frames) == 10 && (Frame.strike?(last_frame) || Frame.spare?(last_frame)) ->
          # the 10th frame hit a strike or a spare, we allow one more frame with one hit at least
          append_new_frame(hits, frames)

        Enum.count(frames) == 10 ->
          {:end_of_game, frames}

        Frame.strike?(last_frame) || Frame.spare?(last_frame) || Frame.done?(last_frame) ->
          append_new_frame(hits, frames)

        Frame.exceed_frame_limit?(last_frame, hits) == true ->
          {:exceed_frame_limit, frames}

        true ->
          update_and_append_frame(hits, last_frame, reversed_frames)
      end

    {:reply, {message, updated_frames}, updated_frames}
  end

  defp append_new_frame(hits, existing_frames) do
    frame = %Frame{
      first_throw_pins_hits: hits,
      score: hits
    }

    {:hit, existing_frames ++ [frame]}
  end

  defp update_and_append_frame(hits, current_frame, reversed_frames)
       when length(reversed_frames) <= 1 do
    updated_current_frame = Frame.add_hits(current_frame, hits)
    updated_frames = Enum.reverse(reversed_frames, [updated_current_frame])
    {:hit, updated_frames}
  end

  # this is where we complete the value of a frame
  defp update_and_append_frame(hits, current_frame, reversed_frames) do
    [last_frame | older_frames] = reversed_frames
    updated_current_frame = Frame.add_hits(current_frame, hits)

    updated_frames =
      cond do
        Frame.strike?(last_frame) == true ->
          # the last frame was a strike
          # we need the score of frame before it
          # we need the score of the frame after it, which is the current frame
          [frame_before_strike | much_older_frames] = older_frames

          last_frame_score =
            frame_before_strike.score + updated_current_frame.score + @bonus_point

          last_frame = Map.put(last_frame, :score, last_frame_score)

          Enum.reverse(much_older_frames, [frame_before_strike, last_frame, updated_current_frame])

        Frame.spare?(last_frame) == true ->
          # the last frame was a spare
          # we need the score of frame before it
          # we need the first_throw_pin_hits of the frame after it, which is the current frame
          [frame_before_strike | much_older_frames] = older_frames

          last_frame_score =
            frame_before_strike.score + updated_current_frame.first_throw_pins_hits + @bonus_point

          last_frame = Map.put(last_frame, :score, last_frame_score)

          Enum.reverse(much_older_frames, [frame_before_strike, last_frame, updated_current_frame])

        true ->
          Enum.reverse(reversed_frames, [updated_current_frame])
      end

    {:hit, updated_frames}
  end

  def handle_call(:reset, _from, frames) do
    {:reply, frames, []}
  end

  def handle_call(:game_score, _from, frames) do
    score = Enum.reduce(frames, 0, &(&1.score + &2))

    {:reply, score, frames}
  end

  # def roll(name \\ __MODULE__, no_of_pins) when is_integer(no_of_pins) and no_of_pins < 11 do
  #   GenServer.call(name, {:throw_ball, no_of_pins})
  # end

  # def reset_state(name \\ __MODULE__) do
  #   GenServer.call(name, :reset)
  # end

  # def get_game_score(name \\ __MODULE__) do
  #   GenServer.call(name, :game_score)
  # end
end
