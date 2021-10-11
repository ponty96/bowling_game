defmodule BowlingHouse.GameStorage do
  @ets_table :bowling_game

  def initialize() do
    :ets.new(@ets_table, [:set, :public, :named_table])
  end

  def insert_new(game_id, state) do
    :ets.insert_new(@ets_table, {game_id, state})
  end

  def insert(game_id, state) do
    :ets.insert(@ets_table, {game_id, state})
  end

  def lookup(game_id) do
    :ets.lookup(@ets_table, game_id)
  end

  def delete(game_id) do
    :ets.delete(@ets_table, game_id)
  end
end
