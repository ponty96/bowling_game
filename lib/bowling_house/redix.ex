defmodule BowlingHouse.GameCache.Redix do
  @moduledoc false

  @callback command(Redix.command()) ::
              {:ok, Redix.Protocol.redis_value()}
              | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}

  @callback pipeline([Redix.command()]) ::
              {:ok, [Redix.Protocol.redis_value()]}
              | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}

  def child_spec(_args) do
    config = config()

    redis_options = [
      database: config[:redis_database],
      host: config[:redis_host],
      port: config[:redis_port]
    ]

    connection_pool_size = config[:connection_pool_size]

    # Specs for the Redix connections.
    children =
      for i <- 0..(connection_pool_size - 1) do
        redis_options = redis_options ++ [name: :"redix_game_cache#{i}"]
        Supervisor.child_spec({Redix, redis_options}, id: {Redix, i})
      end

    # Spec for the supervisor that will supervise the Redix connections.
    %{
      id: BowlingHouse.GameCache.RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  @spec command(Redix.command()) ::
          {:ok, Redix.Protocol.redis_value()}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def command(command) do
    Redix.command(:"redix_game_cache#{random_index()}", command, timeout: 30_000)
  end

  @spec pipeline([Redix.command()]) ::
          {:ok, [Redix.Protocol.redis_value()]}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def pipeline(pipeline) do
    Redix.pipeline(:"redix_game_cache#{random_index()}", pipeline)
  end

  defp random_index do
    connection_pool_size = config()[:connection_pool_size]
    rem(System.unique_integer([:positive]), connection_pool_size)
  end

  defp config do
    Application.get_env(:bowling_house, :game_cache)
  end
end
