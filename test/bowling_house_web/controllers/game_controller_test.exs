defmodule BowlingHouseWeb.GameControllerTest do
  use BowlingHouseWeb.ConnCase

  alias BowlingHouse.GameManager

  test "POST /api/game", %{conn: conn} do
    # validate that the game manager returns not_found for a non existing game_id
    non_existing_game_id = Ecto.UUID.generate()
    assert GameManager.get_game_state(non_existing_game_id) == :not_found

    conn = post(conn, "/api/game")
    assert %{"game_id" => game_id} = json_response(conn, 200)

    assert GameManager.get_game_state(game_id) == []
  end

  test "PUT /api/game/:id", %{conn: conn} do
    # start game
    game_id = Ecto.UUID.generate()
    GameManager.new(game_id)
    assert GameManager.get_game_state(game_id) == []

    balls_rolled = Enum.random(1..9)

    conn =
      put(conn, "/api/game/#{game_id}", %{
        "balls" => balls_rolled
      })

    assert %{
             "data" => %{
               "frames" => [
                 %{
                   "first_throw_pins_hits" => ^balls_rolled,
                   "score" => ^balls_rolled,
                   "second_throw_pins_hits" => nil
                 }
               ],
               "game_id" => ^game_id,
               "game_score" => ^balls_rolled
             },
             "message" => "hit"
           } = json_response(conn, 201)
  end

  test "GET /api/game/:id", %{conn: conn} do
    game_id = Ecto.UUID.generate()
    GameManager.new(game_id)
    assert GameManager.get_game_state(game_id) == []

    first_balls_rolled = Enum.random(1..9)
    second_balls_rolled = Enum.random(1..first_balls_rolled)

    GameManager.roll(game_id, first_balls_rolled)
    GameManager.roll(game_id, second_balls_rolled)

    Process.sleep(500)

    conn = get(conn, "/api/game/#{game_id}")

    expected_score = first_balls_rolled + second_balls_rolled

    assert %{
             "data" => %{
               "frames" => [
                 %{
                   "first_throw_pins_hits" => ^first_balls_rolled,
                   "score" => ^expected_score,
                   "second_throw_pins_hits" => ^second_balls_rolled
                 }
               ],
               "game_id" => ^game_id,
               "game_score" => ^expected_score
             },
             "message" => "Retrieved Successfully"
           } = json_response(conn, 200)
  end

  test "DELETE /api/game/:id", %{conn: conn} do
    game_id = Ecto.UUID.generate()
    GameManager.new(game_id)
    assert GameManager.get_game_state(game_id) == []

    first_balls_rolled = Enum.random(1..9)
    second_balls_rolled = Enum.random(1..first_balls_rolled)

    GameManager.roll(game_id, first_balls_rolled)
    GameManager.roll(game_id, second_balls_rolled)

    Process.sleep(500)

    conn = delete(conn, "/api/game/#{game_id}")

    assert %{"game_id" => game_id} == json_response(conn, 204)

    assert {:error, :not_found} == GameManager.roll(game_id, first_balls_rolled)
  end
end
