defmodule BowlingHouseWeb.GameController do
  use BowlingHouseWeb, :controller
  alias BowlingHouse.GameManager
  alias BowlingHouseWeb.GameView

  def create(conn, _params) do
    new_game_id = Ecto.UUID.generate()
    _new_game = GameManager.new(new_game_id)

    conn
    |> json(%{game_id: new_game_id})
  end

  def update(conn, %{"id" => game_id, "balls" => balls}) do
    case GameManager.roll(game_id, balls) do
      {:error, :not_found} ->
        render_404(conn)

      {:exceed_frame_limit, game_state} ->
        game_score = GameManager.get_game_score(game_id)

        conn
        |> put_status(422)
        |> put_view(GameView)
        |> render("show.json", %{
          game_state: game_state,
          game_id: game_id,
          message: "Can't roll balls, exceeds frame limit",
          game_score: game_score
        })

      {:end_of_game, game_state} ->
        game_score = GameManager.get_game_score(game_id)

        conn
        |> put_status(200)
        |> put_view(GameView)
        |> render("show.json", %{
          game_state: game_state,
          game_id: game_id,
          message: "End of Game, thank you for playing",
          game_score: game_score
        })

      {message, game_state} ->
        game_score = GameManager.get_game_score(game_id)

        conn
        |> put_status(201)
        |> put_view(GameView)
        |> render("show.json", %{
          game_state: game_state,
          game_id: game_id,
          message: message,
          game_score: game_score
        })
    end
  end

  def show(conn, %{"id" => game_id}) do
    case GameManager.get_game_state(game_id) do
      :not_found ->
        render_404(conn)

      game_state ->
        game_score = GameManager.get_game_score(game_id)

        conn
        |> put_status(200)
        |> put_view(GameView)
        |> render("show.json", %{
          game_state: game_state,
          game_id: game_id,
          message: "Retrieved Successfully",
          game_score: game_score
        })
    end
  end

  def delete(conn, %{"id" => game_id}) do
    :ok = GameManager.end_game(game_id)

    conn
    |> put_status(204)
    |> json(%{
      game_id: game_id
    })
  end

  defp render_404(conn) do
    conn
    |> put_status(404)
    |> json(%{
      message: "not found"
    })
  end
end
