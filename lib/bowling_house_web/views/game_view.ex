defmodule BowlingHouseWeb.GameView do
  use BowlingHouseWeb, :view

  def render("show.json", %{
        game_state: frames,
        game_score: game_score,
        game_id: game_id,
        message: message
      }) do
    %{
      message: message,
      data: %{
        game_id: game_id,
        frames: render_many(frames, __MODULE__, "frame.json", as: :frame),
        game_score: game_score
      }
    }
  end

  def render("frame.json", %{
        frame: frame
      }) do
    %{
      first_throw_pins_hits: frame.first_throw_pins_hits,
      score: frame.score,
      second_throw_pins_hits: frame.second_throw_pins_hits
    }
  end
end
