defmodule BowlingHouse.GameManagerTest do
  use BowlingHouse.DataCase, async: true

  alias BowlingHouse.GameManager
  alias BowlingHouse.Frame
  alias BowlingHouse.GameStorage

  describe "new/1" do
    test "it starts a GameEngine and creates a record in the GameStorage" do
      game_id = Ecto.UUID.generate()

      assert :ok == GameManager.new(game_id)

      assert [{^game_id, []}] = GameStorage.lookup(game_id)

      assert 0 == GenServer.call(via_tuple(game_id), :game_score)
    end
  end

  describe "roll/2" do
    test "it rolls the ball for a game with a running GameEngine" do
      game_id = Ecto.UUID.generate()

      assert :ok == GameManager.new(game_id)

      balls_rolled = Enum.random(1..9)

      expected_state = [
        %Frame{
          first_throw_pins_hits: balls_rolled,
          score: balls_rolled
        }
      ]

      assert {:hit, ^expected_state} = GameManager.roll(game_id, balls_rolled)

      assert ^expected_state = GameManager.get_game_state(game_id)
    end

    test "it starts a GameEngine, and rolls the ball when a valid record of the game_id exists in our storage withou an active GameEngine" do
      game_id = Ecto.UUID.generate()

      GameStorage.insert(game_id, _frames = [])

      # we assert that the call to the game engine failed because the process was not found(started)
      assert catch_exit(GenServer.call(via_tuple(game_id), :game_score)) ==
               {:noproc,
                {GenServer, :call,
                 [{:via, Registry, {BowlingHouse.GameEngineRegistry, game_id}}, :game_score, 5000]}}

      balls_rolled = Enum.random(1..9)

      expected_state = [
        %Frame{
          first_throw_pins_hits: balls_rolled,
          score: balls_rolled
        }
      ]

      assert {:hit, ^expected_state} = GameManager.roll(game_id, balls_rolled)

      assert ^expected_state = GameManager.get_game_state(game_id)
    end

    test "it returns an :exceed_frame_limit message when their is an attempt to roll balls beyond the frame limit of 10" do
      game_id = Ecto.UUID.generate()
      GameManager.new(game_id)
      assert GameManager.get_game_state(game_id) == []

      first_balls_rolled = Enum.random(5..9)

      GameManager.roll(game_id, first_balls_rolled)

      # force exceed frame
      balls_rolled = first_balls_rolled + 1

      expected_state = [
        %Frame{
          first_throw_pins_hits: first_balls_rolled,
          score: first_balls_rolled
        }
      ]

      assert {:exceed_frame_limit, ^expected_state} = GameManager.roll(game_id, balls_rolled)
    end
  end

  describe "get_game_state/1" do
    test "it returns the expected game state" do
      game_id = Ecto.UUID.generate()

      assert :ok == GameManager.new(game_id)

      balls_rolled = Enum.random(1..9)
      assert {:hit, _state} = GameManager.roll(game_id, balls_rolled)

      assert [
               %Frame{
                 first_throw_pins_hits: ^balls_rolled,
                 score: ^balls_rolled
               }
             ] = GameManager.get_game_state(game_id)
    end

    test "it returns :not_found if the game_id does not exist in our storage" do
      non_existing_game_id = Ecto.UUID.generate()
      assert GameManager.get_game_state(non_existing_game_id) == :not_found
    end
  end

  describe "end_game/1" do
    test "it ends the game, clears the storage and exits the GameEngine process" do
      game_id = Ecto.UUID.generate()
      decoy_game_id = Ecto.UUID.generate()

      assert :ok == GameManager.new(game_id)

      # start a decoy game
      assert :ok == GameManager.new(decoy_game_id)

      assert [{^game_id, []}] = GameStorage.lookup(game_id)

      assert :ok == GameManager.end_game(game_id)

      assert :not_found == GameManager.get_game_state(game_id)

      # we assert that the call to the game engine failed because the process was not found(started)
      assert catch_exit(GenServer.call(via_tuple(game_id), :game_score)) ==
               {:noproc,
                {GenServer, :call,
                 [{:via, Registry, {BowlingHouse.GameEngineRegistry, game_id}}, :game_score, 5000]}}

      # decoy game GameEngine and storage record still exist
      assert GenServer.call(via_tuple(decoy_game_id), :game_score) == 0
    end
  end

  defp via_tuple(game_id) do
    {:via, Registry, {BowlingHouse.GameEngineRegistry, game_id}}
  end
end
