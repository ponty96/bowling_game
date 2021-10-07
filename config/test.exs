import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :bowling_house, BowlingHouse.Repo,
  username: "postgres",
  password: "postgres",
  database: "bowling_house_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bowling_house, BowlingHouseWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "e+uo25orGIiZiXbH6d2yJWA4EIVsbGg7mEydWFVPZswrCwgsDzT0himkdq6WyACE",
  server: false

# In test we don't send emails.
config :bowling_house, BowlingHouse.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
