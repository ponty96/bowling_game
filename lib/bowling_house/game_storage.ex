defmodule BowlingHouse.GameStorage do
  @ets_table :bowling_game
  alias BowlingHouse.GameCache.Redix

  def initialize() do
    :ets.new(@ets_table, [:set, :public, :named_table])
  end

  def insert_new(game_id, state) do
    Redix.command(["SETNX", game_id, encode_redis_data(state)])
  end

  def insert(game_id, state) do
    Redix.command(["SET", game_id, encode_redis_data(state)])
  end

  defp encode_redis_data([]) do
    ""
  end

  defp encode_redis_data(state) do
    Jason.encode!(state)
  end

  def lookup(game_id) do
    case Redix.command(["GET", game_id]) do
      {:ok, nil} ->
        []

      {:ok, ""} ->
        [{game_id, []}]

      {:ok, state_as_string} ->
        state = decode_from_redis(state_as_string)
        [{game_id, state}]
    end
  end

  def delete(game_id) do
    Redix.command(["DEL", game_id])
  end

  defp decode_from_redis(string) do
    Jason.decode!(string, keys: :atoms) |> Enum.map(&struct(BowlingHouse.Frame, &1))
  end
end
