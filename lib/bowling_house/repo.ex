defmodule BowlingHouse.Repo do
  use Ecto.Repo,
    otp_app: :bowling_house,
    adapter: Ecto.Adapters.Postgres
end
