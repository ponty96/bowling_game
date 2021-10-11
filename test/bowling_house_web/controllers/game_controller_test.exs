defmodule BowlingHouseWeb.GameControllerTest do
  use BowlingHouseWeb.ConnCase, async: true

  alias BowlingHouse.GameManager

  setup do
    ExUnit.Callbacks.on_exit(fn ->
      BowlingHouse.GameCache.Redix.command(["FLUSHALL"])
    end)
  end

  describe "POST /api/game" do
    test "success: it initiates a new game instance", %{conn: conn} do
      # validate that the game manager returns not_found for a non existing game_id
      non_existing_game_id = Ecto.UUID.generate()
      assert GameManager.get_game_state(non_existing_game_id) == :not_found

      conn = post(conn, "/api/game")
      assert %{"game_id" => game_id} = json_response(conn, 200)

      assert GameManager.get_game_state(game_id) == []
    end
  end

  describe "PUT /api/game/:id" do
    test "success: it rolls the ball and updates the game state frames", %{conn: conn} do
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

    test "error: it returns an error when the game has ended", %{conn: conn} do
      # start game
      game_id = Ecto.UUID.generate()
      GameManager.new(game_id)
      assert GameManager.get_game_state(game_id) == []

      for _frame <- _ten_frames = 1..10 do
        balls_to_roll = Enum.random(1..5)

        GameManager.roll(game_id, balls_to_roll)
        GameManager.roll(game_id, balls_to_roll)
      end

      balls_rolled_after_end_of_game = Enum.random(1..5)

      conn =
        put(conn, "/api/game/#{game_id}", %{
          "balls" => balls_rolled_after_end_of_game
        })

      response = json_response(conn, 200)

      assert response["message"] == "End of Game, thank you for playing"
    end

    test "does not add new ball to frame, and returns the appropriate message when the ball rolled exceeds the frame limit of 10",
         %{conn: conn} do
      # start game
      game_id = Ecto.UUID.generate()
      GameManager.new(game_id)
      assert GameManager.get_game_state(game_id) == []

      first_balls_rolled = Enum.random(5..9)

      # force exceed frame
      balls_to_roll = first_balls_rolled + 1

      GameManager.roll(game_id, first_balls_rolled)

      conn =
        put(conn, "/api/game/#{game_id}", %{
          "balls" => balls_to_roll
        })

      assert %{
               "data" => %{
                 "frames" => [
                   %{
                     "first_throw_pins_hits" => ^first_balls_rolled,
                     "score" => ^first_balls_rolled,
                     "second_throw_pins_hits" => nil
                   }
                 ],
                 "game_id" => ^game_id,
                 "game_score" => ^first_balls_rolled
               },
               "message" => "Can't roll balls, exceeds frame limit"
             } = json_response(conn, 422)
    end
  end

  describe "GET /api/game/:id" do
    test "success: it returns the game state", %{conn: conn} do
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

    test "error: it returns a 404 response when the game_id passed does not exist", %{conn: conn} do
      non_existing_game_id = Ecto.UUID.generate()
      conn = get(conn, "/api/game/#{non_existing_game_id}")

      assert json_response(conn, 404)
    end
  end

  describe "DELETE /api/game/:id" do
    test "success: it ends the game and clears our game engine storage", %{conn: conn} do
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
end
